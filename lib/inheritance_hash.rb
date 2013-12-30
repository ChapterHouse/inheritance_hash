require 'inheritance_hash/version'

class InheritanceHash < Hash

  #:nodoc:
  alias :__has_key? :has_key?
  private(:__has_key?)

  (superclass.instance_methods - Object.instance_methods).each do |m|
    undef_method(m) #unless m =~ /(^__|^nil\?|^send$|^object_id$|^tap$|^class$)/
  end

  #:doc:
  def self.[](*args) #:nodoc:
    ihash = InheritanceHash.new
    if args.size == 1
      if args.first.is_a?(Array)
        args.first.each { |item| ihash[item.first] = item.last }
      else
        if args.first.respond_to?(:to_h)
          args.first.to_h.each { |key, value| ihash[key] = value }
        else
          raise ArgumentError.new('odd number of arguments for Hash')
        end
      end
    elsif args.size.even?
      args.each_slice(2) { |key, value| ihash[key] = value }
    else
      raise ArgumentError.new('odd number of arguments for Hash')
    end
    ihash
  end

  def initialize(*args) #:nodoc:
    super
  end

  def [](key) #:nodoc:
    if __has_key?(key)
      super
    elsif inheritable?(key) && !deleted?(key) && up_chain.has_key?(key)
      up_chain[key]
    else
      default(key)
    end
  end

  def []=(key, value) #:nodoc:
    key_set(key)
    super
  end

  def assoc(obj) #:nodoc:
    if __has_key?(object)
      super
    else
      up_chain.assoc(obj)
    end
  end

  def clear #:nodoc:
    self.deleted_keys += (up_chain.keys - noninheritable)
    super
  end

  # This is not yet implemented as it will be neccessary to prevent children from causing
  # side effects in other children by affecting the parent's comparison method.
  def compare_by_identity
    raise NotImplementedError
  end

  def delete(key) #:nodoc:
    if noninheritable?(key)
      super
    else
      if deleted?(key)
        block_given? ? yield(key) : default
      else
        if __has_key?(key)
          super
        elsif up_chain.has_key?(key)
          delete_key(key)
          up_chain[key]
        else
          block_given? ? yield(key) : default
        end
      end
    end

  end

  def delete_if #:nodoc:
    if block_given?
      each { |key, value| delete(key) if yield(key, value) }
      self
    else
      raise NotImplementedError, 'External iterator not yet supported'
    end
  end

  # Define a key as uninheritable.
  # If the key is not defined in this hash it will not check the parent.
  # The key does not need to currently exist in the hash.
  def dont_inherit(key)
    noninheritable << key
    noninheritable.uniq!
  end

  def fetch(*args) #:nodoc:
    if args.length < 1 || args.length > 2
      raise ArgumentError, "wrong number of arguments (#{args.length} for 1..2)"
    elsif args.length == 2 && block_given?
      warn('warning: block supersedes default value argument')
    end

    key = args.first

    if __has_key?(key)
      super
    elsif inheritable?(key) && !deleted?(key) && up_chain.has_key?(key)
      up_chain.fetch(key)
    else
      if block_given?
        yield(key)
      elsif args.length == 2
        args[1]
      else
        raise KeyError, "key not found #{args.first.inspect}"
      end
    end
  end

  def has_key?(key) #:nodoc:
    super || up_chain.has_key?(key)
  end


  # Mark a key as inheritable (the default).
  # If the key was previously marked as uninheritable, this will remove that setting.
  # The key does not need to currently exist in the hash.
  def inherit(key)
    noninheritable.delete(key)
  end

  # Set the hash to inherit from. Usually this would be another InheritanceHash but can be a normal Hash.
  # Note: Using a normal Hash will not automatically undelete keys in the child InheritanceHash if they are reset in the parent Hash.
  def inherit_from(hash)
    unless hash == self
      up_chain.unchain_from(self) if up_chain.respond_to?(:unchain_from, true)
      self.up_chain = hash
      up_chain.down_chain_to(self) if up_chain.respond_to?(:down_chain_to, true)
    end
  end

  def keep_if #:nodoc:
    if block_given?
      each { |key, value| delete(key) unless yield(key, value) }
      self
    else
      raise NotImplementedError, 'External iterator not yet supported'
    end
  end

  def merge(*args)
    self.class[super]
  end

  def merge!(*args)
    x = super
    puts x.inspect
    replace(x)
    #replace(super)
  end

  def replace(other_hash)
    puts "#replace(#{other_hash.inspect})"
    # Make sure we clear out values that are inherited too.
    clear
    super(other_hash.to_h)
  end

  def respond_to?(*args) #:nodoc:
    [:inherit, :dont_inherit, :inherit_from].include?(args.first) || args[1] && [:down_chain_to, :unchain_from].include?(args.first) || {}.respond_to?(*args)
  end

  def to_h #:nodoc:
    up_chain.to_h.select { |key, _| inheritable?(key) }.merge(super).select { |key, _| !deleted?(key) }
  end



  protected

  def down_chain_to(hash) #:nodoc:
    unless hash == self
      down_chains << hash
      down_chains.uniq!
    end
  end

  def key_set(key) #:nodoc:
    if inheritable?(key)
      deleted_keys.delete(key)
      #deleted(key).delete
      down_chains.each { |down_chain| down_chain.key_set(key) }
    end
  end

  def unchain_from(hash) #:nodoc:
    down_chains.delete(hash)
  end


  # Inherited values we are pretending to have 'deleted' but may be restored if the up_chain sets another value.
  def deleted_keys
    @deleted_keys ||= []
  end

  def deleted_keys=(new_array)
    @deleted_keys = Array(new_array).flatten.uniq!
  end

  private


  attr_writer :up_chain, :down_chains#, :deleted_keys

  def deleted?(key)
    deleted_keys.include?(key)
    #(deleted.keys + deleted_keys).include?(key)
  end

  def delete_key(key)
    deleted_keys << key
    deleted_keys.uniq!
  end


  def up_chain
    @up_chain ||= {}
  end

  def inheritable?(key)
    !noninheritable?(key)
  end

  def noninheritable
    @noninheritable ||= []
  end

  def noninheritable?(key)
    noninheritable.include?(key)
  end

  def method_missing(method_name, *args, &block)
    to_h.send(*(args.unshift(method_name)), &block)
  end

  def down_chains
    @down_chains ||= []
  end

end

