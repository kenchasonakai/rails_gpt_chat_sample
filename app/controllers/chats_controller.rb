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
    @chat = Chat.new(chat_params)
    if @chat.save
      redirect_to chats_path
    else
      render :new
    end
  end

  private

  def chat_params
    params.require(:chat).permit(:question).merge(answer: fetch_gpt_response(params[:chat][:question]))
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
end
