require 'mechanize'
require 'nokogiri'
require 'addressable/uri'
require 'uri'

class OpenGraph
  attr_accessor :src, :url, :type, :title, :description, :images, :metadata, :response, :original_images

  def initialize(src)
    @src = src
    @doc = nil
    @images = []
    @metadata = {}
    parse_opengraph
    check_images_path
  end

  private
  TWITTER_PATTEN = /^http[s]?:\/\/twitter\.com\/[a-zA-Z0-9_]{1,15}\/status\/\d*\/?$/

  def parse_opengraph
    begin
      agent = Mechanize.new
      agent.set_proxy ENV['CRAWLING_PROXY_HOST'], ENV['CRAWLING_PROXY_PORT'] if Rails.env.production?
      agent.user_agent_alias = 'Windows IE 10'
      agent.follow_meta_refresh = true
      agent.redirect_ok = :all
      agent.redirection_limit = 5
      agent.gzip_enabled = false
      agent.request_headers = { 'accept-language' => 'ko-KR,ko;q=0.8,en-US;q=0.6,en;q=0.4' }
      @doc = agent.get(@src)
      if @doc.encoding_error? and @doc.encodings.include?('ks_c_5601-1987')
        @doc.encoding = 'euc-kr'
      end
    rescue
      @title = @url = @src
      return
    end
    load_from_opengraph
    load_from_page(overwrite: (@url || @src)=~TWITTER_PATTEN)
  end

  def load_from_opengraph
    if @doc.present? and @doc.respond_to?(:css)
      attrs_list = %w(title url type description)
      @doc.css('meta').each do |m|
        if m.attribute('property') && m.attribute('property').to_s.match(/^og:(.+)$/i)
          m_content = m.attribute('content').to_s.strip
          metadata_name = m.attribute('property').to_s.gsub("og:", "")
          @metadata = add_metadata(@metadata, metadata_name, m_content)
          case metadata_name
            when *attrs_list
              self.instance_variable_set("@#{metadata_name}", m_content) unless m_content.empty?
            when "image"
              add_image(m_content)
          end
        end
      end
    end
  end

  def load_from_page(overwrite:)
    if @doc.present? and @doc.respond_to?(:xpath)
      if @title.to_s.empty? or overwrite
        if @doc.title.present?
          @title = @doc.title
        elsif @doc.xpath("//head//title").size > 0
          @title = @doc.xpath("//head//title").first.text.to_s.strip
        end
      end

      @url = @src if @url.to_s.empty?

      if (@description.to_s.empty? or overwrite) && description_meta = @doc.xpath("//head//meta[@name='description']").first
        @description = description_meta.attribute("content").to_s.strip
      end

      if @description.to_s.empty?
        @description = fetch_first_text(@doc)
      end

      fetch_images(@doc, "//head//link[@rel='image_src']", "href") if @images.empty?
      fetch_images(@doc, "//img", "src") if @images.empty?
    end
  end

  def check_images_path
    @original_images = @images.dup
    uri = Addressable::URI.parse(@src)
    imgs = @images.dup
    @images = []
    imgs.each do |img|
      if Addressable::URI.parse(img).host.nil?
        full_path = uri.join(img).to_s
        add_image(full_path)
      else
        add_image(img)
      end
    end
  end

  def add_image(image_url)
    @images << image_url unless @images.include?(image_url) || image_url.to_s.empty?
  end

  def fetch_images(doc, xpath_str, attr)
    doc.xpath(xpath_str).each do |link|
      add_image(link.attribute(attr).to_s.strip)
    end
  end

  def fetch_first_text(doc)
    doc.xpath('//p').each do |p|
      s = p.text.to_s.strip
      return s if s.length > 20
    end
  end

  def add_metadata(metadata_container, path, content)
    path_elements = path.split(':')
    if path_elements.size > 1
      current_element = path_elements.delete_at(0)
      path = path_elements.join(':')
      if metadata_container[current_element.to_sym]
        path_pointer = metadata_container[current_element.to_sym].last
        index_count = metadata_container[current_element.to_sym].size
        metadata_container[current_element.to_sym][index_count - 1] = add_metadata(path_pointer, path, content)
        metadata_container
      else
        metadata_container[current_element.to_sym] = []
        metadata_container[current_element.to_sym] << add_metadata({}, path, content)
        metadata_container
      end
    else
      metadata_container[path.to_sym] ||= []
      metadata_container[path.to_sym] << {'_value'.to_sym => content}
      metadata_container
    end
  end
end
