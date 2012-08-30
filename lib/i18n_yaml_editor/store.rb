# encoding: utf-8

require "set"

module I18nYamlEditor
  class Store
    def initialize *new_keys
      self.keys = Set.new
      new_keys.each {|key| self.keys.add(key)}
    end

    attr_accessor :keys

    def filter_keys filter
      self.keys.select {|k| k.key =~ filter}
    end

    def key_categories
      self.keys.map {|k| k.key.split(".").first}.uniq
    end

    def locales
      self.keys.map(&:locale).uniq
    end

    def find_key params
      self.keys.detect {|key|
        params.all? {|k,v| key.send(k) == v}
      }
    end

    def update_key key, locale, text
      key = find_key(:key => key, :locale => locale)
      key.text = text
    end

    def create_missing_keys
      unique_keys = self.keys.map(&:key).uniq
      unique_keys.each {|key|
        existing_translations = self.keys.select {|k| k.key == key}
        missing_translations = self.locales - existing_translations.map(&:locale)
        missing_translations.each {|locale|
          file = existing_translations.first.file.split(".")
          file[-2] = locale
          file = file.join(".")
          new_key = Key.new(:locale => locale, :key => key, :file => file, :text => nil)
          self.keys.add(new_key)
        }
      }
    end

    def from_yaml yaml, file=nil
      keys = IYE.flatten_hash(yaml)
      keys.each {|full_key, text|
        _, locale, key_name = full_key.match(/^(.*?)\.(.*)/).to_a
        key = Key.new(:key => key_name, :file => file, :locale => locale, :text => text)
        self.keys.add(key)
      }
    end

    def to_yaml
      result = {}
      files = self.keys.group_by(&:file)
      files.each {|file, file_keys|
        file_result = {}
        file_keys.each {|key|
          file_result[key.full_key] = key.text
        }
        result[file] = IYE.nest_hash(file_result)
      }
      result
    end
  end
end
