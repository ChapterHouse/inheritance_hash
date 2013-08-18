require 'inheritance_hash/version'

class InheritanceHash < Hash

  alias :__has_key? :has_key?

  instance_methods.each do |m|
    undef_method(m) unless m =~ /(^__|^nil\?|^send$|^object_id$|^tap$|^class$)/
  end

  def self.[](*args)
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

  def initialize(*args)
    super
  end

  def [](key)
    if __has_key?(key)
      super
    elsif inheritable?(key) && !deleted?(key) && up_chain.has_key?(key)
      up_chain[key]
    else
      default(key)
    end
  end

  def []=(key, value)
    key_set(key)
    super
  end

  def assoc(obj)
    if __has_key?(object)
      super
    else
      up_chain.assoc(obj)
    end
  end

  def clear
    deleted_keys += (up_chain.keys - noninheritable)
    deleted_keys.uniq!
    super
  end

  def compare_by_identity
    raise NotImplementedError, 'Probably will never be implemented as it allows for children to cause side effects in other children.'
  end

  def delete(key)
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

  def delete_if
    if block_given?
      each { |key, value| delete(key) if yield(key, value) }
      self
    else
      raise NotImplementedError, 'External iterator not yet supported'
    end
  end

  def dont_inherit(key)
    noninheritable << key
    noninheritable.uniq!
  end

  def fetch(*args)
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

  def has_key?(key)
    __has_key?(key) || up_chain.has_key?(key)
  end

  def inherit(key)
    noninheritable.delete(key)
  end

  def inherit_from(hash)
    unless hash == self
      self.up_chain = hash
      up_chain.down_chain_to(self) if up_chain.respond_to?(:down_chain_to)
    end
  end

  def keep_if
    if block_given?
      each { |key, value| delete(key) unless yield(key, value) }
      self
    else
      raise NotImplementedError, 'External iterator not yet supported'
    end
  end

  def respond_to?(*args)
    [:inherit, :dont_inherit, :inherit_from].include?(args.first) || {}.respond_to?(*args)
  end

  def to_h
    up_chain.to_h.select { |key, _| inheritable?(key) }.merge(super).select { |key, _| !deleted?(key) }
  end

  protected

  attr_writer :up_chain, :down_chains

  def key_set(key)
    if inheritable?(key)
      deleted_keys.delete(key)
      #deleted(key).delete
      down_chains.each { |down_chain| down_chain.key_set(key) }
    end
  end

  def down_chain_to(hash)
    unless hash == self
      down_chains << hash
      down_chains.uniq!
    end
  end

  private

  def deleted?(key)
    deleted_keys.include?(key)
    #(deleted.keys + deleted_keys).include?(key)
  end

  def delete_key(key)
    deleted_keys << key
    deleted_keys.uniq!
  end

  # Inherited values we are pretending to have 'deleted' but may be restored if the up_chain sets another value.
  def deleted_keys
    @deleted_keys ||= []
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

