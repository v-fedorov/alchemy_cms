module Alchemy
  module Admin
    class ContentsController < Alchemy::Admin::BaseController
      helper 'alchemy/admin/essences'

      authorize_resource class: Alchemy::Content

      def new
        @element = Element.find(params[:element_id])
        @options = options_from_params
        @contents = @element.available_contents || @element.grouped_contents
        @content = @element.contents.build
      end

      def create
        @element = Element.find(params[:content][:element_id])
        if @element.grouped_content_description_for(params[:content][:name])
          @content = Content.create_group_from_scratch(@element, content_params)
        else
          @content = []
          @content << Content.create_from_scratch(@element, content_params)
        end
        @options = options_from_params
        @html_options = params[:html_options] || {}
        if select_essence_no_values?
          @options = options_for_select_essence
        end
        if picture_gallery_editor?
          @content.update_essence(picture_id: params[:picture_id])
          @options = options_for_picture_gallery
          @content_dom_id = "#add_picture_#{@element.id}"
        else
          @content_dom_id = "#add_content_for_element_#{@element.id}"
        end
        @locals = essence_editor_locals
      end

      def update
        @content = Content.find(params[:id])
        @content.update_essence(content_params)
      end

      def order
        params[:content_ids].each do |id|
          content = Content.find(id)
          content.move_to_bottom
        end
        @notice = _t("Successfully saved content position")
      end

      def destroy
        @content = Content.find(params[:id].split("/"))
        @element = @content.first.element
        @position = @content.first.position
        @content_dom_id = @content.map {|content| [content.dom_id]}
        @content_group_id = @content.map {|content| content.id}.join('_')
        @notice = _t("Successfully deleted content group")
        @content.each(&:destroy)
      end

      private

      def content_params
        params.require(:content).permit(:element_id, :name, :ingredient, :essence_type)
      end

      def picture_gallery_editor?
        params[:content][:essence_type] == 'Alchemy::EssencePicture' && @options[:grouped] == 'true'
      end

      def select_essence_no_values?
        unless @options[:select_values].present?
          @content.each do |content|
            return true if content.essence_type.eql?("Alchemy::EssenceSelect")
          end
        end
      end

      def options_for_picture_gallery
        @gallery_pictures = @element.contents.gallery_pictures
        @dragable = @gallery_pictures.size > 1
        @options.merge(dragable: @dragable)
      end

      def options_for_select_essence
        select_essence = @content.detect{|c| c.essence_type == "Alchemy::EssenceSelect"}
        select_values = select_essence.settings
        @options.merge(select_values)
      end

      def essence_editor_locals
        {
          content: @content,
          options: @options.symbolize_keys,
          html_options: @html_options.symbolize_keys
        }
      end

    end
  end
end
