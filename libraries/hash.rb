# encoding: utf-8

class Hash
  def keys_to_s
    replace(inject({}) { |h, (k, v)| h[k.to_s] = v; h })
  end
end
