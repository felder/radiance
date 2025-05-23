# frozen_string_literal: true

class ThumbnailPresenter < Blacklight::ThumbnailPresenter

  # @param [SolrDocument] document
  # @param [ActionView::Base] view_context scope for linking and generating urls
  #                                        as well as for invoking "thumbnail_method"
  # @param [Blacklight::Configuration::ViewConfig] view_config
  def initialize(document, view_context, view_config)
    @document = document
    @view_context = view_context
    @view_config = view_config
  end

  def render(image_options = {})
    thumbnail_value(image_options)
  end

  ##
  # Does the document have a thumbnail to render?
  #
  # @return [Boolean]
  def exists?
    thumbnail_method.present? ||
      (thumbnail_field && thumbnail_value_from_document.present?) ||
      default_thumbnail.present?
  end

  ##
  # Render the thumbnail, if available, for a document and
  # link it to the document record.
  #
  # @param [Hash] image_options to pass to the image tag
  # @param [Hash] url_options to pass to #link_to_document
  # @return [String]
  def thumbnail_tag image_options = {}, url_options = {}
    value = thumbnail_value(image_options)
    return value if value.nil? || url_options[:suppress_link]

    view_context.link_to_document document, value, url_options
  end

  def render_thumbnail_alt_text()
    prefix = document[:doctype_s] || 'Document'
    total_pages = document[:blob_ss] ? document[:blob_ss].length : 1
    if total_pages > 1
      page_number = "#{document[:blob_ss].find_index(thumbnail_value_from_document)}".to_i
      if page_number.to_s.instance_of?(String)
        if document[:common_doctype_s] == 'document'
          prefix += ' page '
        end
        prefix += "#{page_number + 1} of #{total_pages}"
      end
    end
    document_title = unless document[:doctitle_ss].nil? then "titled #{document[:doctitle_ss][0]}" else 'no title available' end
    source = unless document[:source_s].nil? then ", source: #{document[:source_s]}" else '' end
    "#{prefix} #{document_title}#{source}".html_safe
  end

  private

  delegate :thumbnail_field, :thumbnail_method, :default_thumbnail, to: :view_config

  # @param [Hash] image_options to pass to the image tag
  def thumbnail_value(image_options)
    value = if thumbnail_method
              view_context.send(thumbnail_method, document, image_options)
            elsif thumbnail_field
              image_options['alt'] = render_thumbnail_alt_text
              image_url = 'https://webapps.cspace.berkeley.edu/cinefiles/imageserver/blobs/' + thumbnail_value_from_document + '/derivatives/Medium/content'
              view_context.image_tag image_url, image_options if image_url.present?
            end

    value || default_thumbnail_value(image_options)
  end

end
