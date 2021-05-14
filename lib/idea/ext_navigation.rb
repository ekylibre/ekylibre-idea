module Idea
  class ExtNavigation
    def self.add_navigation_xml_to_existing_tree
      ext_navigation = ExtNavigation.new
      ext_navigation.build_new_tree
    end

    attr_reader :idea_navigation_tree, :new_navigation_tree,
                :idea_xml_navigation_childrens

    def initialize
      @idea_navigation_tree = Ekylibre::Navigation::Tree
                                    .load_file(idea_navigation_file_path,
                                               :navigation,
                                               %i[part group item])
      @idea_xml_navigation_childrens = init_idea_navigation_childrens

    end

    def build_new_tree
      @idea_navigation_tree.children.each do |child|
        after_part = after_part_value(child)

        Ekylibre::Navigation.tree.insert_part_after(child, after_part)
      end

      @new_navigation_tree = Ekylibre::Navigation.tree
      @new_navigation_tree
    end

    private

      def init_idea_navigation_childrens
        parts = navigation_to_xml.xpath('//part')

        parts.map do |part|
          { after_part: part.attribute('after-part').value, node: part }
        end
      end

      def after_part_value(idea_navigation_child)
        selected_child = @idea_xml_navigation_childrens.select do |idea_xml_navigation_child|
          idea_xml_navigation_child[:node].attribute('name').value == idea_navigation_child.name.to_s
        end

        selected_child.first[:after_part]
      end

      def navigation_to_xml
        navigation_xml_file = File.open(idea_navigation_file_path)

        xml = Nokogiri::XML(navigation_xml_file) do |config|
          config.strict.nonet.noblanks
        end

        navigation_xml_file.close

        xml
      end

      def idea_navigation_file_path
        Idea.root.join('config', 'navigation.xml')
      end
  end
end
