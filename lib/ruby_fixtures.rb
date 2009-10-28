require "yaml"
require "digest/md5"
begin
  require "factory_girl"
rescue LoadError => e
  $stderr.puts "#{e}\nPlease install gem factory_girl!"
end

class RubyFixtures
  
  class << self
    
    attr_reader :fixtures
    @fixtures = Hash.new { |hash, key| hash[key] = {}}

    @checksum_file = RAILS_ROOT + "/test/.fixtures_checksum"
    @fixtures_file = RAILS_ROOT + "/test/fixtures.rb"

    def load
      instance_eval(read_fixtures_file)
    end
    
    def export
      if checksum == read_checksum
        return
      end
      
      puts "Exporting ruby fixtures to yaml"
      load
      delete_old_yml_fixtures
      write_yaml
      write_checksum
      puts "Done"
    end
    
    def scenario(name, &block)
      puts "** Scenario #{name}"
      @scenario_name = name
      self.class.send(:define_method, name, &block)
      __send__(name)
      @scenario_name = nil
    end
    
    def copy(name)
      __send__(name)
    end
    
    def to(fixture_model_name, attributes = {})
      @fixture_model_name = fixture_model_name
      
      if block_given?
        @to_attributes ||= {}
        @to_attributes[fixture_model_name] = attributes
        yield      
        @to_attributes.delete(fixture_model_name)
      end
      
      unless self.class.method_defined?(fixture_model_name) 
        self.class.send(:define_method, fixture_model_name) do |fixture_name|
          @fixtures[fixture_model_name][fixture_name_in_scenario(fixture_name)]
        end
      end
    end

    def update(fixture_model_name, fixture_name, attributes)
      add(fixture_model_name, fixture_name, __send__(fixture_model_name.to_s.pluralize, fixture_name), attributes)
    end

    def add(*params)
      if !params[1].kind_of? Symbol
        name, attributes_or_record, attributes = params
      else
        fixture_model_name, name, attributes_or_record, attributes = params
        to(fixture_model_name.to_s.pluralize.to_sym)
      end

      attributes_or_record ||= {}
      name_in_scenario = fixture_name_in_scenario(name)
      
      if attributes_or_record.kind_of?(Hash)
        
        attributes_or_record.each do |attr, fixture_name|
          next unless fixture_name.kind_of? Symbol
          association_name = attr.to_s.pluralize.to_sym
          attributes_or_record[attr] = __send__(association_name, fixture_name) if @fixtures.keys.include?(association_name)
        end

        attributes_or_record.merge!(@to_attributes[@fixture_model_name]) if @to_attributes && @to_attributes[@fixture_model_name]

        attributes_or_record = Factory(@fixture_model_name.to_s.singularize.to_sym, attributes_or_record)
        
      elsif attributes
        attributes.each do |attribute, value|
          attributes_or_record.__send__("#{attribute}=", value)
        end
        attributes_or_record.save!
      end

      returning(add_fixture(@fixture_model_name, name_in_scenario, attributes_or_record, name)) do |record|
        yield record if block_given?
      end
    end

    private

      def write_yaml
        unless File.directory?(RAILS_ROOT + "/test/fixtures/")
          puts "Creating fixtures directory"
          Dir.mkdir(RAILS_ROOT + "/test/fixtures/")
        end
      
        @fixtures.each do |fixture_model_name, records|
          fixture_table_name = fixture_model_name.to_s.classify.constantize.table_name
          File.open(RAILS_ROOT + "/test/fixtures/#{fixture_table_name}.yml", "w") do |fp|
            record_attributes = {}
            records.each do |key, record|
              record_attributes[key.to_s] = cleaned_up_attributes_for_record(record)
             end
            YAML.dump(record_attributes, fp)
          end
        end
      end
    
      def cleaned_up_attributes_for_record(record)
        attributes = record.attributes.dup
        attributes.each do |key, value|
          case value
          when Date, Time, DateTime
            attributes[key] = value.to_s(:db)
          when Array, Hash
            attributes[key] = value.to_yaml
          end
        end
      
        attributes.stringify_keys!
      end

      def delete_old_yml_fixtures
        Dir.glob(RAILS_ROOT + "/test/fixtures/*.yml").each do |file|
          File.delete(file)
        end
      end
    
      def add_fixture(fixture_model_name, name, record, logging_name = name)
        verb = !@fixtures[fixture_model_name][name.to_sym].nil? ? 'Updating' : 'Creating'
        puts "#{verb} #{fixture_model_name.to_s.singularize} :#{logging_name}"
      
        @fixtures[fixture_model_name][name.to_sym] = record
      end
    
      def fixture_name_in_scenario(name)
        (@scenario_name ? "#{@scenario_name}_#{name}" : name).to_sym
      end
    
      def checksum
        Digest::SHA1.hexdigest(read_fixtures_file)
      end
    
      def read_checksum
        IO.read(@checksum_file) rescue nil
      end
    
      def write_checksum
        File.open(@checksum_file, 'w') { |f| f.write(checksum) }
      end
    
      def read_fixtures_file
        File.read(@fixtures_file)
      end
  end
end
