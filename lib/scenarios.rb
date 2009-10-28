class RubyFixtures
  module Scenarios
  
    def self.included(base)
      base.fixture_table_names.each do |table_name|
        base.class_eval <<-EOS, __FILE__, __LINE__ 
          def #{table_name}_with_scenarios(*fixtures)
            force_reload = fixtures.pop if fixtures.last == true || fixtures.last == :reload
            scenario = self.class.read_inheritable_attribute(:scenario)
            fixtures.map! { |fixture| scenario.to_s + '_' + fixture.to_s } if scenario
            fixtures << force_reload if force_reload

            __send__("#{table_name}_without_scenarios", fixtures)
          end
        EOS
        base.alias_method_chain table_name, :scenarios
      end
      
      base.class_eval <<-EOS
        class_inheritable_reader :scenario
        def self.scenario(name)
          write_inheritable_attribute :scenario, name
        end
        
        def scenario(name)
          @previous_scenario = self.class.read_inheritable_attribute(:scenario) || :none
          self.class.write_inheritable_attribute(:scenario, name)
        end
        
        def teardown
          if @previous_scenario
            self.class.write_inheritable_attribute(:scenario, @previous_scenario == :none ? nil : @previous_scenario) 
            @previous_scenario = nil
          end
        end
      EOS
    end
  end
end