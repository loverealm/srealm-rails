require 'rails_helper'

describe 'api/v1/pub/videos' do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:doorkeeper_application) { FactoryGirl.create(:doorkeeper_application) }
  let!(:doorkeeper_access_token) do
    FactoryGirl.create(:doorkeeper_access_token, application: doorkeeper_application,
                                                 resource_owner_id: user.id)
  end
  let!(:description) { 'description' }
  let!(:video) { { base64_data: "data:video/mp4;base64, #{VideoBase64::video_base64}", original_filename: 'test.mp4' } }

  before do
    allow_any_instance_of(Paperclip::Attachment).to receive(:save).and_return(true)
  end

  describe 'POST api/v1/pub/videos' do
    it 'returns status 201 for successful create' do
      post '/api/v1/pub/videos', access_token: doorkeeper_access_token.token, description: description, video: video

      expect(response.status).to eq 201
    end

    it 'retuns 422 with video error when video is blank' do
      post "/api/v1/pub/videos", access_token: doorkeeper_access_token.token, video: nil

      expect(JSON.parse(response.body)["errors"]).to eq "Video can't be blank"
    end

    it 'returns 422 for errors in saving' do
      post '/api/v1/pub/videos', access_token: doorkeeper_access_token.token, description: nil

      expect(response.status).to eq 422
    end
  end

  describe 'PUT api/v1/mobile/videos/{id}' do
    let!(:content_video) { FactoryGirl.create(:content_video, user: user) }

    it 'returns status 200 for successful update' do
      put "/api/v1/pub/videos/#{content_video.id}", access_token: doorkeeper_access_token.token, description: "Updated video.", video: video

      expect(response.status).to eq 200
    end
    
    it 'returns 422 for errors in updating' do
      put "/api/v1/pub/videos/#{content_video.id}", access_token: doorkeeper_access_token.token, description: nil, video: video

      expect(response.status).to eq 422
    end

    it 'increase the number of views' do
      show_count = content_video.show_count
      put "/api/v1/pub/videos/#{content_video.id}/show_count", access_token: doorkeeper_access_token.token
      show_count += 1
      expect(json['show_count']).to eq show_count
    end
  end

  describe 'GET api/v1/pub/videos/:id' do
    let!(:content_video) { FactoryGirl.create(:content_video, user: user) }

    it 'returns status 200 for successful response' do
      get "/api/v1/pub/videos/#{content_video.id}", access_token: doorkeeper_access_token.token

      expect(response.status).to eq 200
    end
  
    it 'returns status 404 when there is no video with given id' do
      content_video.destroy

      get "/api/v1/pub/videos/#{content_video.id}", access_token: doorkeeper_access_token.token

      expect(response.status).to eq 404
    end
    
    it 'returns video fields in response' do
      video_content = FactoryGirl.create(:content_video, user: user)
      video_content.liked_by user

      comment = FactoryGirl.create(:comment, user: user, content: video_content)

      get "/api/v1/pub/videos/#{video_content.id}", access_token: doorkeeper_access_token.token

      expect(json['id']).to eq video_content.id
      expect(json['description']).to eq video_content.description
      expect(json['video_url']).to eq video_content.video.url
      expect(json['number_of_likes']).to eq 1
      expect(json['created_at']).to eq video_content.created_at.to_i
      expect(json['updated_at']).to eq video_content.updated_at.to_i
      
      expect(json['user']['id']).to eq video_content.user.id
      expect(json['user']['full_name']).to eq video_content.user.full_name
      expect(json['user']['avatar_url']).to eq video_content.user.avatar.url

      expect(json['comments'].first['id']).to eq comment.id
      expect(json['comments'].first['body']).to eq comment.body
      expect(json['comments'].first['created_at']).to eq comment.created_at.to_i
      expect(json['comments'].first['updated_at']).to eq comment.updated_at.to_i

      expect(json['comments'].first['user']['id']).to eq comment.user.id
      expect(json['comments'].first['user']['full_name']).to eq comment.user.full_name
      expect(json['comments'].first['user']['avatar_url']).to eq comment.user.avatar.url
    end
  end
end
