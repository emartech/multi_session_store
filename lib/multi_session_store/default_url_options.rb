module MultiSessionStore
  module DefaultUrlOptions
    def default_url_options
      options = params[:subsession_id] ? {subsession_id: params[:subsession_id]} : {}
      begin
        super.merge options
      rescue NoMethodError
        options
      end
    end
  end
end
