class Api::V1::Mobile::VideosController < Api::V1::Pub::VideosController
  include MobileAuthorizer
end
