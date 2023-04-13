class ChatsController < ApplicationController
  def index
    @chats = Chat.all
  end

  def new
    @chat = Chat.new
  end

  def show
    @chat = Chat.find(params[:id])
  end

  def create
    fetch_github_repo_blobs_url(params[:chat][:question])
    # @chat = Chat.new(chat_params)
    # if @chat.save
    #   redirect_to chats_path
    # else
    #   render :new
    # end
  end

  private

  def chat_params
    # params.require(:chat).permit(:question).merge(answer: fetch_gpt_response(params[:chat][:question]))
    params.require(:chat).permit(:question).merge(answer: fetch_github_repo_blobs_url(params[:chat][:question]))
  end

  def fetch_gpt_response(text)
    client = OpenAI::Client.new(access_token: Rails.application.credentials.config.dig(:openai, :access_token))

    response = client.chat(
        parameters: {
            model: "gpt-3.5-turbo",
            messages: [{ role: "user", content: text }],
            temperature: 0.7,
        })

    response.dig("choices", 0, "message", "content")
  end

  def fetch_github_repo_blobs_url(github_url)
    repo_name = github_url.split('/').slice(-2, 2).join('/')
    client = Octokit::Client.new(access_token: Rails.application.credentials.config.dig(:github, :access_token))
    # Railsのレビュー対象のディレクトリ
    review_target_paths = %w(app/controllers app/models app/views app/jobs app/mailers app/channels app/helpers app/assets)
    review_target_paths.each do |path|
      client.contents(repo_name, path: path).each do |blob|
        url = blob[:download_url]
        next if url.blank?

        github_code = Net::HTTP.get_response(URI.parse(url)).body
        next if github_code.blank?

        base_prompt = "あなたはプロのWebエンジニアです。次のRuby on Railsのコードを読みコードレビューを行ってください。指摘事項がない場合はLGTMとだけ返信してください。\n\n"
        p path + '/' + url.split('/').last
        p fetch_gpt_response(base_prompt + "```\n" +  github_code.force_encoding(Encoding::UTF_8) + "\n```")
      end
    end
  end
end
