# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180222142231) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"

  create_table "activities", force: :cascade do |t|
    t.integer  "trackable_id"
    t.string   "trackable_type"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "key"
    t.text     "parameters"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.boolean  "checked",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type", using: :btree
  add_index "activities", ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type", using: :btree
  add_index "activities", ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type", using: :btree

  create_table "appointments", force: :cascade do |t|
    t.integer  "mentee_id"
    t.integer  "mentor_id"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.time     "duration"
    t.boolean  "finished"
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.datetime "schedule_for"
    t.datetime "re_schedule_for"
    t.datetime "started_at"
    t.datetime "end_at"
    t.string   "session_id"
    t.string   "kind",            default: "video"
    t.string   "latitude"
    t.string   "longitude"
    t.string   "location"
    t.string   "status",          default: "pending"
  end

  add_index "appointments", ["mentee_id"], name: "index_appointments_on_mentee_id", using: :btree
  add_index "appointments", ["mentor_id"], name: "index_appointments_on_mentor_id", using: :btree

  create_table "attack_requests", force: :cascade do |t|
    t.string   "path"
    t.string   "browser_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "attack_requests", ["browser_key"], name: "index_attack_requests_on_browser_key", using: :btree
  add_index "attack_requests", ["path"], name: "index_attack_requests_on_path", using: :btree

  create_table "banned_users", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "banable_id"
    t.string   "banable_type"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "kind"
  end

  add_index "banned_users", ["banable_type", "banable_id"], name: "index_banned_users_on_banable_type_and_banable_id", using: :btree
  add_index "banned_users", ["user_id"], name: "index_banned_users_on_user_id", using: :btree

  create_table "bootsy_image_galleries", force: :cascade do |t|
    t.integer  "bootsy_resource_id"
    t.string   "bootsy_resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bootsy_image_galleries", ["bootsy_resource_id"], name: "index_bootsy_image_galleries_on_bootsy_resource_id", using: :btree
  add_index "bootsy_image_galleries", ["bootsy_resource_type"], name: "index_bootsy_image_galleries_on_bootsy_resource_type", using: :btree

  create_table "bootsy_images", force: :cascade do |t|
    t.string   "image_file"
    t.integer  "image_gallery_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bootsy_images", ["image_gallery_id"], name: "index_bootsy_images_on_image_gallery_id", using: :btree

  create_table "bot_activities", force: :cascade do |t|
    t.integer  "bot_question_id"
    t.string   "user_answer"
    t.integer  "conversation_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "bot_activities", ["bot_question_id"], name: "index_bot_activities_on_bot_question_id", using: :btree
  add_index "bot_activities", ["conversation_id"], name: "index_bot_activities_on_conversation_id", using: :btree

  create_table "bot_custom_answers", force: :cascade do |t|
    t.string   "text"
    t.integer  "logged_user_message_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "bot_custom_answers", ["logged_user_message_id"], name: "index_bot_custom_answers_on_logged_user_message_id", using: :btree

  create_table "bot_questions", force: :cascade do |t|
    t.string   "text"
    t.string   "field_for_update"
    t.integer  "position"
    t.integer  "bot_scenario_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "when_to_run"
    t.jsonb    "available_answers"
  end

  add_index "bot_questions", ["bot_scenario_id"], name: "index_bot_questions_on_bot_scenario_id", using: :btree

  create_table "bot_scenarios", force: :cascade do |t|
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "description"
    t.string   "scenario_type"
  end

  create_table "break_news", force: :cascade do |t|
    t.string   "title"
    t.text     "subtitle"
    t.integer  "content_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "break_news", ["content_id"], name: "index_break_news_on_content_id", using: :btree
  add_index "break_news", ["user_id"], name: "index_break_news_on_user_id", using: :btree

  create_table "broadcast_messages", force: :cascade do |t|
    t.string   "custom_phones_file_name"
    t.string   "custom_phones_content_type"
    t.integer  "custom_phones_file_size"
    t.datetime "custom_phones_updated_at"
    t.text     "message"
    t.string   "from"
    t.string   "kind",                                               default: "normal"
    t.integer  "branches",                                           default: [],                     array: true
    t.string   "age_range",                                          default: "0,100"
    t.integer  "gender"
    t.string   "countries",                                          default: [],                     array: true
    t.integer  "user_group_id"
    t.datetime "created_at",                                                             null: false
    t.datetime "updated_at",                                                             null: false
    t.integer  "user_id"
    t.boolean  "send_sms",                                           default: false
    t.integer  "unread_messages",                                    default: [],                     array: true
    t.integer  "qty_sms_sent",                                       default: 0
    t.text     "raw_phone_numbers",                                  default: ""
    t.string   "to_kind",                                            default: "members"
    t.decimal  "amount",                     precision: 8, scale: 2, default: 0.0
    t.string   "phone_numbers",                                      default: [],                     array: true
    t.boolean  "is_paid",                                            default: true
  end

  add_index "broadcast_messages", ["user_group_id"], name: "index_broadcast_messages_on_user_group_id", using: :btree
  add_index "broadcast_messages", ["user_id"], name: "index_broadcast_messages_on_user_id", using: :btree

  create_table "cache_user_feeds", force: :cascade do |t|
    t.integer "user_id"
    t.text    "popular_list"
  end

  add_index "cache_user_feeds", ["user_id"], name: "index_cache_user_feeds_on_user_id", using: :btree

  create_table "church_devotions", force: :cascade do |t|
    t.date     "devotion_day"
    t.string   "title"
    t.text     "descr"
    t.integer  "user_id"
    t.integer  "user_group_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "church_devotions", ["user_group_id"], name: "index_church_devotions_on_user_group_id", using: :btree
  add_index "church_devotions", ["user_id"], name: "index_church_devotions_on_user_id", using: :btree

  create_table "church_member_invitations", force: :cascade do |t|
    t.integer  "user_group_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "pastor_name"
    t.integer  "user_id"
    t.integer  "qty",               default: 0
  end

  add_index "church_member_invitations", ["user_group_id"], name: "index_church_member_invitations_on_user_group_id", using: :btree
  add_index "church_member_invitations", ["user_id"], name: "index_church_member_invitations_on_user_id", using: :btree

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string   "data_file_name",               null: false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable", using: :btree
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type", using: :btree

  create_table "comments", force: :cascade do |t|
    t.text     "body"
    t.integer  "user_id"
    t.integer  "story_id"
    t.integer  "post_status_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "content_id"
    t.integer  "parent_id"
    t.integer  "cached_votes_score", default: 0
    t.integer  "answers_counter",    default: 0
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "deleted_at"
  end

  add_index "comments", ["content_id"], name: "index_comments_on_content_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "content_actions", force: :cascade do |t|
    t.integer  "content_id"
    t.string   "action_name"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "content_actions", ["action_name"], name: "index_content_actions_on_action_name", using: :btree
  add_index "content_actions", ["content_id"], name: "index_content_actions_on_content_id", using: :btree
  add_index "content_actions", ["created_at"], name: "index_content_actions_on_created_at", using: :btree
  add_index "content_actions", ["user_id"], name: "index_content_actions_on_user_id", using: :btree

  create_table "content_file_visitors", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "content_file_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "content_file_visitors", ["content_file_id"], name: "index_content_file_visitors_on_content_file_id", using: :btree
  add_index "content_file_visitors", ["user_id"], name: "index_content_file_visitors_on_user_id", using: :btree

  create_table "content_files", force: :cascade do |t|
    t.integer  "content_id"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.string   "tmp_key"
    t.integer  "order_file",         default: 0
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "gallery_files_id"
    t.string   "gallery_files_type"
    t.integer  "visits_counter",     default: 0
  end

  add_index "content_files", ["content_id"], name: "index_content_files_on_content_id", using: :btree
  add_index "content_files", ["gallery_files_type", "gallery_files_id"], name: "index_content_files_on_gallery_files_type_and_gallery_files_id", using: :btree
  add_index "content_files", ["tmp_key"], name: "index_content_files_on_tmp_key", using: :btree

  create_table "content_live_videos", force: :cascade do |t|
    t.integer  "content_id"
    t.string   "session"
    t.string   "broadcast_id"
    t.jsonb    "broadcast_urls",          default: {}
    t.string   "video_url"
    t.integer  "views_counter",           default: 0
    t.datetime "finished_at"
    t.string   "screenshot_file_name"
    t.string   "screenshot_content_type"
    t.integer  "screenshot_file_size"
    t.datetime "screenshot_updated_at"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "archive_id"
    t.string   "project_id"
  end

  add_index "content_live_videos", ["content_id"], name: "index_content_live_videos_on_content_id", using: :btree

  create_table "content_phone_invitations", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "phone_number"
    t.string   "kind",           default: "prayer"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "status",         default: "pending"
    t.string   "contact_name"
    t.string   "email"
    t.integer  "invitable_id"
    t.string   "invitable_type"
  end

  add_index "content_phone_invitations", ["kind"], name: "index_content_phone_invitations_on_kind", using: :btree
  add_index "content_phone_invitations", ["user_id"], name: "index_content_phone_invitations_on_user_id", using: :btree

  create_table "content_prayers", force: :cascade do |t|
    t.integer  "content_id"
    t.integer  "user_id"
    t.integer  "user_requester_id"
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.datetime "prayed_until"
  end

  add_index "content_prayers", ["content_id"], name: "index_content_prayers_on_content_id", using: :btree
  add_index "content_prayers", ["user_id"], name: "index_content_prayers_on_user_id", using: :btree
  add_index "content_prayers", ["user_requester_id"], name: "index_content_prayers_on_user_requester_id", using: :btree

  create_table "contents", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content_type"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "cached_votes_score",  default: 0
    t.integer  "shares_count",        default: 0
    t.datetime "publishing_at"
    t.integer  "comments_count",      default: 0
    t.tsvector "tsv"
    t.string   "video_file_name"
    t.string   "video_content_type"
    t.integer  "video_file_size"
    t.datetime "video_updated_at"
    t.integer  "show_count",          default: 0
    t.integer  "owner_id"
    t.integer  "reports_counter",     default: 0
    t.datetime "last_activity_time",  default: '2017-01-23 13:08:36'
    t.integer  "user_group_id"
    t.datetime "answered_at"
    t.integer  "cached_love",         default: 0
    t.integer  "cached_pray",         default: 0
    t.integer  "cached_amen",         default: 0
    t.integer  "cached_angry",        default: 0
    t.integer  "cached_sad",          default: 0
    t.integer  "cached_wow",          default: 0
    t.string   "privacy_level",       default: "public"
    t.string   "public_uid"
    t.integer  "content_source_id"
    t.string   "content_source_type"
    t.datetime "deleted_at"
  end

  add_index "contents", ["cached_votes_score"], name: "index_contents_on_cached_votes_score", using: :btree
  add_index "contents", ["content_source_type", "content_source_id"], name: "index_contents_on_content_source_type_and_content_source_id", using: :btree
  add_index "contents", ["content_type"], name: "index_contents_on_content_type", using: :btree
  add_index "contents", ["description"], name: "contents_on_description_idx", using: :gin
  add_index "contents", ["last_activity_time"], name: "index_contents_on_last_activity_time", using: :btree
  add_index "contents", ["owner_id"], name: "index_contents_on_owner_id", using: :btree
  add_index "contents", ["privacy_level"], name: "index_contents_on_privacy_level", using: :btree
  add_index "contents", ["title"], name: "index_contents_on_title", using: :btree
  add_index "contents", ["tsv"], name: "index_contents_on_tsv", using: :gin
  add_index "contents", ["user_group_id"], name: "index_contents_on_user_group_id", using: :btree
  add_index "contents", ["user_id"], name: "index_contents_on_user_id", using: :btree

  create_table "contents_hash_tags", id: false, force: :cascade do |t|
    t.integer "hash_tag_id"
    t.integer "content_id"
  end

  add_index "contents_hash_tags", ["content_id"], name: "index_contents_hash_tags_on_content_id", using: :btree
  add_index "contents_hash_tags", ["hash_tag_id", "content_id"], name: "index_contents_hash_tags_on_hash_tag_id_and_content_id", using: :btree

  create_table "conversation_members", force: :cascade do |t|
    t.integer  "user_id"
    t.boolean  "is_admin",        default: false
    t.integer  "conversation_id"
    t.datetime "last_seen",       default: '2018-02-08 03:13:07'
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "conversation_members", ["conversation_id"], name: "index_conversation_members_on_conversation_id", using: :btree
  add_index "conversation_members", ["user_id"], name: "index_conversation_members_on_user_id", using: :btree

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "appointment_id"
    t.boolean  "with_bot",           default: false
    t.integer  "bot_scenario_id"
    t.string   "group_title"
    t.integer  "owner_id"
    t.datetime "last_activity"
    t.string   "key"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "qty_messages",       default: 0
    t.integer  "qty_members",        default: 0
    t.boolean  "is_private",         default: true
  end

  add_index "conversations", ["appointment_id"], name: "index_conversations_on_appointment_id", using: :btree
  add_index "conversations", ["bot_scenario_id"], name: "index_conversations_on_bot_scenario_id", using: :btree
  add_index "conversations", ["owner_id"], name: "index_conversations_on_owner_id", using: :btree

  create_table "counselor_reports", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "mentorship_id"
    t.text     "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "counselor_reports", ["mentorship_id"], name: "index_counselor_reports_on_mentorship_id", using: :btree
  add_index "counselor_reports", ["user_id"], name: "index_counselor_reports_on_user_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  add_index "delayed_jobs", ["queue"], name: "delayed_jobs_queue", using: :btree

  create_table "event_attends", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "event_id"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "event_attends", ["event_id"], name: "index_event_attends_on_event_id", using: :btree
  add_index "event_attends", ["user_id"], name: "index_event_attends_on_user_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "name"
    t.string   "location"
    t.datetime "start_at"
    t.datetime "end_at"
    t.text     "description"
    t.string   "keywords"
    t.string   "ticket_url"
    t.integer  "eventable_id"
    t.string   "eventable_type"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.decimal  "price",              precision: 8, scale: 2, default: 0.0
    t.integer  "qty_attending",                              default: 0
    t.integer  "content_id"
  end

  add_index "events", ["content_id"], name: "index_events_on_content_id", using: :btree
  add_index "events", ["eventable_type", "eventable_id"], name: "index_events_on_eventable_type_and_eventable_id", using: :btree

  create_table "feedbacks", force: :cascade do |t|
    t.string   "subject"
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "checked",     default: false
    t.string   "ip"
  end

  add_index "feedbacks", ["checked"], name: "index_feedbacks_on_checked", using: :btree
  add_index "feedbacks", ["user_id"], name: "index_feedbacks_on_user_id", using: :btree

  create_table "hash_tags", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.integer  "mentor_id"
  end

  add_index "hash_tags", ["mentor_id"], name: "index_hash_tags_on_mentor_id", using: :btree
  add_index "hash_tags", ["name"], name: "index_hash_tags_on_name", using: :btree

  create_table "hash_tags_users", id: false, force: :cascade do |t|
    t.integer "hash_tag_id"
    t.integer "user_id"
  end

  add_index "hash_tags_users", ["hash_tag_id", "user_id"], name: "index_hash_tags_users_on_hash_tag_id_and_user_id", using: :btree
  add_index "hash_tags_users", ["user_id"], name: "index_hash_tags_users_on_user_id", using: :btree

  create_table "identities", force: :cascade do |t|
    t.string  "uid"
    t.string  "provider"
    t.integer "user_id"
    t.string  "oauth_token"
  end

  add_index "identities", ["user_id"], name: "index_identities_on_user_id", using: :btree

  create_table "logged_user_messages", force: :cascade do |t|
    t.string   "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mentions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "comment_id"
    t.integer  "content_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "message_id"
  end

  add_index "mentions", ["comment_id"], name: "index_mentions_on_comment_id", using: :btree
  add_index "mentions", ["content_id"], name: "index_mentions_on_content_id", using: :btree
  add_index "mentions", ["message_id"], name: "index_mentions_on_message_id", using: :btree
  add_index "mentions", ["user_id"], name: "index_mentions_on_user_id", using: :btree

  create_table "mentor_categories", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "mentor_categories_users", id: false, force: :cascade do |t|
    t.integer "mentor_category_id", null: false
    t.integer "user_id",            null: false
  end

  create_table "mentorships", force: :cascade do |t|
    t.integer  "mentor_id"
    t.integer  "hash_tag_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.datetime "deleted_at"
  end

  add_index "mentorships", ["deleted_at"], name: "index_mentorships_on_deleted_at", using: :btree
  add_index "mentorships", ["hash_tag_id"], name: "index_mentorships_on_hash_tag_id", using: :btree
  add_index "mentorships", ["mentor_id"], name: "index_mentorships_on_mentor_id", using: :btree

  create_table "messages", force: :cascade do |t|
    t.string   "subject"
    t.text     "body"
    t.integer  "receiver_id"
    t.integer  "sender_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "removed",             default: false
    t.datetime "removed_at"
    t.integer  "conversation_id"
    t.boolean  "daily_message",       default: false
    t.integer  "story_id"
    t.datetime "read_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.string   "kind",                default: "text"
    t.integer  "parent_id"
    t.datetime "deleted_at"
    t.integer  "across_message_id"
    t.string   "across_message_type"
  end

  add_index "messages", ["across_message_type", "across_message_id", "deleted_at"], name: "message_filter_from_broadcasts", using: :btree
  add_index "messages", ["across_message_type", "across_message_id"], name: "index_messages_on_across_message_type_and_across_message_id", using: :btree
  add_index "messages", ["conversation_id", "deleted_at"], name: "index_messages_on_conversation_id_and_deleted_at", using: :btree
  add_index "messages", ["conversation_id"], name: "index_messages_on_conversation_id", using: :btree
  add_index "messages", ["created_at", "deleted_at"], name: "index_messages_on_created_at_and_deleted_at", using: :btree
  add_index "messages", ["deleted_at"], name: "index_messages_on_deleted_at", using: :btree
  add_index "messages", ["receiver_id"], name: "index_messages_on_receiver_id", using: :btree
  add_index "messages", ["sender_id"], name: "index_messages_on_sender_id", using: :btree
  add_index "messages", ["story_id"], name: "index_messages_on_story_id", using: :btree

  create_table "mobile_tokens", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "device_token"
    t.string   "fcm_token"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "current_mode", default: "foreground"
    t.string   "kind",         default: "android"
  end

  add_index "mobile_tokens", ["user_id"], name: "index_mobile_tokens_on_user_id", using: :btree

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", null: false
    t.integer  "application_id",    null: false
    t.string   "token",             null: false
    t.integer  "expires_in",        null: false
    t.text     "redirect_uri",      null: false
    t.datetime "created_at",        null: false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.string   "token",             null: false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        null: false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",                      null: false
    t.string   "uid",                       null: false
    t.string   "secret",                    null: false
    t.text     "redirect_uri",              null: false
    t.string   "scopes",       default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "payment_cards", force: :cascade do |t|
    t.string   "name"
    t.string   "last4"
    t.string   "customer_id"
    t.integer  "user_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "kind"
    t.datetime "deleted_at"
    t.string   "exp"
    t.boolean  "is_default",  default: false
  end

  add_index "payment_cards", ["user_id"], name: "index_payment_cards_on_user_id", using: :btree

  create_table "payments", force: :cascade do |t|
    t.string   "payment_ip"
    t.string   "payment_payer_id"
    t.datetime "payment_at"
    t.string   "payment_token"
    t.string   "payment_transaction_id"
    t.decimal  "amount",                 precision: 8, scale: 2
    t.string   "payment_kind",                                   default: "paypal"
    t.integer  "payable_id"
    t.string   "payable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "goal"
    t.string   "last4"
    t.integer  "payment_card_id"
    t.string   "recurring_period"
    t.text     "recurring_error"
    t.integer  "parent_id"
    t.datetime "recurring_stopped_at"
    t.date     "payment_in"
    t.decimal  "recurring_amount",       precision: 8, scale: 2
    t.datetime "refunded_at"
    t.datetime "transferred_at"
  end

  add_index "payments", ["payable_type", "payable_id"], name: "index_payments_on_payable_type_and_payable_id", using: :btree
  add_index "payments", ["payment_card_id"], name: "index_payments_on_payment_card_id", using: :btree
  add_index "payments", ["user_id"], name: "index_payments_on_user_id", using: :btree

  create_table "phone_number_invitations", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "phone_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "phone_number_invitations", ["phone_number"], name: "index_phone_number_invitations_on_phone_number", using: :btree
  add_index "phone_number_invitations", ["user_id"], name: "index_phone_number_invitations_on_user_id", using: :btree

  create_table "promotions", force: :cascade do |t|
    t.string   "locations",                                  default: [],                 array: true
    t.integer  "age_from",                                   default: 0
    t.integer  "age_to",                                     default: 100
    t.integer  "gender"
    t.string   "demographics",                               default: [],                 array: true
    t.decimal  "budget",             precision: 8, scale: 2
    t.decimal  "remaining_budget",   precision: 8, scale: 2
    t.date     "period_until"
    t.integer  "promotable_id"
    t.string   "promotable_type"
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.string   "website"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.boolean  "is_paid",                                    default: false
    t.datetime "approved_at"
    t.integer  "user_id"
  end

  add_index "promotions", ["is_paid", "approved_at"], name: "index_promotions_on_is_paid_and_approved_at", using: :btree
  add_index "promotions", ["promotable_type", "promotable_id"], name: "index_promotions_on_promotable_type_and_promotable_id", using: :btree
  add_index "promotions", ["user_id"], name: "index_promotions_on_user_id", using: :btree

  create_table "recommends", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "content_id"
    t.integer  "sender_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "recommends", ["content_id"], name: "index_recommends_on_content_id", using: :btree
  add_index "recommends", ["sender_id"], name: "index_recommends_on_sender_id", using: :btree
  add_index "recommends", ["user_id"], name: "index_recommends_on_user_id", using: :btree

  create_table "relationships", force: :cascade do |t|
    t.integer  "follower_id"
    t.integer  "followed_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "relationships", ["followed_id"], name: "index_relationships_on_followed_id", using: :btree
  add_index "relationships", ["follower_id", "followed_id"], name: "index_relationships_on_follower_id_and_followed_id", unique: true, using: :btree
  add_index "relationships", ["follower_id"], name: "index_relationships_on_follower_id", using: :btree

  create_table "reports", force: :cascade do |t|
    t.text     "description"
    t.integer  "target_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "target_type"
    t.boolean  "reviewed",    default: false
    t.integer  "user_id"
  end

  add_index "reports", ["target_id", "target_type"], name: "index_reports_on_target_id_and_target_type", using: :btree
  add_index "reports", ["user_id"], name: "index_reports_on_user_id", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "key"
    t.text     "value"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  create_table "shares", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "content_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "shares", ["content_id", "user_id"], name: "index_shares_on_content_id_and_user_id", using: :btree

  create_table "suggested_users", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "kind"
    t.integer  "suggestandable_id"
    t.string   "suggestandable_type"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "suggested_users", ["kind"], name: "index_suggested_users_on_kind", using: :btree
  add_index "suggested_users", ["suggestandable_type", "suggestandable_id"], name: "index_suggestandable_id_type", using: :btree
  add_index "suggested_users", ["user_id"], name: "index_suggested_users_on_user_id", using: :btree

  create_table "suggestions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "suggested_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.boolean  "interested"
  end

  add_index "suggestions", ["suggested_id"], name: "index_suggestions_on_suggested_id", using: :btree
  add_index "suggestions", ["user_id"], name: "index_suggestions_on_user_id", using: :btree

  create_table "tickets", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "user_id"
    t.integer  "payment_id"
    t.text     "png"
    t.string   "code"
    t.datetime "redeemed_at"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "tickets", ["event_id"], name: "index_tickets_on_event_id", using: :btree
  add_index "tickets", ["payment_id"], name: "index_tickets_on_payment_id", using: :btree
  add_index "tickets", ["user_id"], name: "index_tickets_on_user_id", using: :btree

  create_table "user_anonymities", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "user_id"
  end

  add_index "user_anonymities", ["user_id"], name: "index_user_anonymities_on_user_id", using: :btree

  create_table "user_friend_relationships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "user_to_id"
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "user_friend_relationships", ["user_id"], name: "index_user_friend_relationships_on_user_id", using: :btree
  add_index "user_friend_relationships", ["user_to_id"], name: "index_user_friend_relationships_on_user_to_id", using: :btree

  create_table "user_group_attendances", force: :cascade do |t|
    t.integer  "user_group_id"
    t.integer  "user_group_meeting_id"
    t.integer  "user_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "user_group_attendances", ["created_at", "user_group_id"], name: "index_user_group_attendances_on_created_at_and_user_group_id", using: :btree
  add_index "user_group_attendances", ["user_group_id"], name: "index_user_group_attendances_on_user_group_id", using: :btree
  add_index "user_group_attendances", ["user_group_meeting_id"], name: "index_user_group_attendances_on_user_group_meeting_id", using: :btree
  add_index "user_group_attendances", ["user_id"], name: "index_user_group_attendances_on_user_id", using: :btree

  create_table "user_group_branch_requests", force: :cascade do |t|
    t.integer  "user_group_from_id"
    t.integer  "user_group_to_id"
    t.integer  "user_id"
    t.string   "kind",               default: "branch"
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "user_group_branch_requests", ["user_group_from_id"], name: "index_user_group_branch_requests_on_user_group_from_id", using: :btree
  add_index "user_group_branch_requests", ["user_group_to_id"], name: "index_user_group_branch_requests_on_user_group_to_id", using: :btree
  add_index "user_group_branch_requests", ["user_id"], name: "index_user_group_branch_requests_on_user_id", using: :btree

  create_table "user_group_communions", force: :cascade do |t|
    t.integer  "user_group_id"
    t.integer  "user_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.boolean  "answer"
  end

  add_index "user_group_communions", ["user_group_id"], name: "index_user_group_communions_on_user_group_id", using: :btree
  add_index "user_group_communions", ["user_id"], name: "index_user_group_communions_on_user_id", using: :btree

  create_table "user_group_converts", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "user_group_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "user_group_converts", ["user_group_id"], name: "index_user_group_converts_on_user_group_id", using: :btree
  add_index "user_group_converts", ["user_id"], name: "index_user_group_converts_on_user_id", using: :btree

  create_table "user_group_counselors", force: :cascade do |t|
    t.integer  "user_group_id"
    t.integer  "user_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "user_group_counselors", ["user_group_id"], name: "index_user_group_counselors_on_user_group_id", using: :btree
  add_index "user_group_counselors", ["user_id"], name: "index_user_group_counselors_on_user_id", using: :btree

  create_table "user_group_files", force: :cascade do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "user_group_id"
    t.integer  "user_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "user_group_files", ["user_group_id"], name: "index_user_group_files_on_user_group_id", using: :btree
  add_index "user_group_files", ["user_id"], name: "index_user_group_files_on_user_id", using: :btree

  create_table "user_group_manual_values", force: :cascade do |t|
    t.integer  "user_group_id"
    t.integer  "value"
    t.date     "date"
    t.string   "kind"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "user_group_manual_values", ["kind"], name: "index_user_group_manual_values_on_kind", using: :btree
  add_index "user_group_manual_values", ["user_group_id"], name: "index_user_group_manual_values_on_user_group_id", using: :btree

  create_table "user_group_meeting_nonattendances", force: :cascade do |t|
    t.integer  "user_group_meeting_id"
    t.integer  "user_id"
    t.text     "reason"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "user_group_meeting_nonattendances", ["user_group_meeting_id"], name: "index_nonattendances_on_user", using: :btree
  add_index "user_group_meeting_nonattendances", ["user_id"], name: "index_user_group_meeting_nonattendances_on_user_id", using: :btree

  create_table "user_group_meetings", force: :cascade do |t|
    t.integer  "user_group_id"
    t.string   "title"
    t.string   "day"
    t.string   "hour"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.text     "description",   default: ""
  end

  add_index "user_group_meetings", ["user_group_id"], name: "index_user_group_meetings_on_user_group_id", using: :btree

  create_table "user_groups", force: :cascade do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.string   "banner_file_name"
    t.string   "banner_content_type"
    t.integer  "banner_file_size"
    t.datetime "banner_updated_at"
    t.string   "key",                 default: ""
    t.string   "name"
    t.text     "description",         default: ""
    t.string   "kind",                default: "general"
    t.string   "privacy_level",       default: "open"
    t.integer  "hashtag_ids",         default: [],                     array: true
    t.integer  "request_member_ids",  default: [],                     array: true
    t.integer  "conversation_id"
    t.integer  "user_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "parent_id"
    t.string   "latitude"
    t.string   "longitude"
    t.boolean  "is_verified",         default: false
  end

  add_index "user_groups", ["conversation_id"], name: "index_user_groups_on_conversation_id", using: :btree
  add_index "user_groups", ["key"], name: "index_user_groups_on_key", using: :btree
  add_index "user_groups", ["kind"], name: "index_user_groups_on_kind", using: :btree
  add_index "user_groups", ["user_id"], name: "index_user_groups_on_user_id", using: :btree

  create_table "user_logins", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_logins", ["user_id"], name: "index_user_logins_on_user_id", using: :btree

  create_table "user_photos", force: :cascade do |t|
    t.text     "url"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "content_id"
  end

  add_index "user_photos", ["content_id"], name: "index_user_photos_on_content_id", using: :btree
  add_index "user_photos", ["user_id"], name: "index_user_photos_on_user_id", using: :btree

  create_table "user_relationships", force: :cascade do |t|
    t.boolean  "is_admin",       default: false
    t.integer  "groupable_id"
    t.string   "groupable_type"
    t.integer  "user_id"
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "kind",           default: "group_member"
    t.datetime "last_visit"
    t.datetime "baptised_at"
    t.boolean  "is_primary",     default: false
  end

  add_index "user_relationships", ["groupable_type", "groupable_id"], name: "index_user_relationships_on_groupable_type_and_groupable_id", using: :btree
  add_index "user_relationships", ["user_id"], name: "index_user_relationships_on_user_id", using: :btree

  create_table "user_settings", force: :cascade do |t|
    t.integer "user_id"
    t.string  "contact_numbers", default: [], array: true
  end

  add_index "user_settings", ["user_id"], name: "index_user_settings_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                                                        default: "",    null: false
    t.string   "encrypted_password",                                           default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                                default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "location"
    t.text     "biography"
    t.integer  "sex"
    t.string   "country"
    t.date     "birthdate"
    t.string   "nick"
    t.boolean  "is_newbie",                                                    default: true
    t.boolean  "receive_notification",                                         default: true
    t.boolean  "receive_messages_only_from_followers",                         default: false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "password_confirmations"
    t.datetime "notifications_checked_at"
    t.string   "cover_file_name"
    t.string   "cover_content_type"
    t.integer  "cover_file_size"
    t.datetime "cover_updated_at"
    t.string   "phone_number"
    t.tsvector "tsv"
    t.datetime "last_seen"
    t.jsonb    "meta_info",                                                    default: {}
    t.string   "relationship_status"
    t.boolean  "verified",                                                     default: false
    t.datetime "invited_friends_at"
    t.string   "mention_key"
    t.datetime "last_sign_out_at"
    t.integer  "default_mentor_id"
    t.integer  "qty_pending_friends",                                          default: 0
    t.integer  "qty_friends",                                                  default: 0
    t.integer  "qty_recent_activities",                                        default: 0
    t.datetime "deactivated_at"
    t.string   "time_zone"
    t.integer  "roles"
    t.datetime "prevent_posting_until"
    t.datetime "prevent_commenting_until"
    t.datetime "deleted_at"
    t.datetime "user_cache_key"
    t.decimal  "credits",                              precision: 8, scale: 2, default: 0.0
  end

  add_index "users", ["first_name"], name: "index_users_on_first_name", using: :btree
  add_index "users", ["last_name"], name: "index_users_on_last_name", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["roles"], name: "index_users_on_roles", using: :btree
  add_index "users", ["tsv"], name: "index_users_on_tsv", using: :gin

  create_table "verses", force: :cascade do |t|
    t.integer "book_num"
    t.string  "book_id"
    t.string  "book"
    t.integer "chapter"
    t.integer "verse"
    t.text    "text"
    t.integer "translation_id"
  end

  add_index "verses", ["book_id"], name: "index_verses_on_book_id", using: :btree
  add_index "verses", ["translation_id"], name: "index_verses_on_translation_id", using: :btree
  add_index "verses", ["verse"], name: "index_verses_on_verse", using: :btree

  create_table "votes", force: :cascade do |t|
    t.integer  "votable_id"
    t.string   "votable_type"
    t.integer  "voter_id"
    t.string   "voter_type"
    t.boolean  "vote_flag"
    t.string   "vote_scope"
    t.integer  "vote_weight"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "votes", ["votable_id", "votable_type", "vote_scope"], name: "index_votes_on_votable_id_and_votable_type_and_vote_scope", using: :btree
  add_index "votes", ["voter_id", "voter_type", "vote_scope"], name: "index_votes_on_voter_id_and_voter_type_and_vote_scope", using: :btree

  create_table "watchdog_elements", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "key"
    t.integer  "observed_id"
    t.string   "observed_type"
    t.datetime "date_until"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.datetime "confirmed_at"
    t.text     "reason",          default: ""
    t.datetime "reverted_at"
    t.integer  "reverted_by_id"
    t.text     "reverted_reason", default: ""
    t.integer  "user_confirm_id"
  end

  add_index "watchdog_elements", ["observed_type", "observed_id"], name: "index_watchdog_elements_on_observed_type_and_observed_id", using: :btree
  add_index "watchdog_elements", ["user_id"], name: "index_watchdog_elements_on_user_id", using: :btree

  create_table "words", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "bot_activities", "bot_questions"
  add_foreign_key "bot_activities", "conversations"
  add_foreign_key "bot_custom_answers", "logged_user_messages"
  add_foreign_key "cache_user_feeds", "users"
  add_foreign_key "church_devotions", "user_groups"
  add_foreign_key "church_devotions", "users"
  add_foreign_key "content_actions", "contents"
  add_foreign_key "content_actions", "users"
  add_foreign_key "content_file_visitors", "content_files"
  add_foreign_key "content_file_visitors", "users"
  add_foreign_key "content_live_videos", "contents"
  add_foreign_key "content_phone_invitations", "users"
  add_foreign_key "content_prayers", "contents"
  add_foreign_key "content_prayers", "users"
  add_foreign_key "conversations", "bot_scenarios"
  add_foreign_key "event_attends", "events"
  add_foreign_key "event_attends", "users"
  add_foreign_key "mobile_tokens", "users"
  add_foreign_key "payment_cards", "users"
  add_foreign_key "suggestions", "users"
  add_foreign_key "tickets", "events"
  add_foreign_key "tickets", "payments"
  add_foreign_key "tickets", "users"
  add_foreign_key "user_group_attendances", "user_group_meetings"
  add_foreign_key "user_group_attendances", "user_groups"
  add_foreign_key "user_group_attendances", "users"
  add_foreign_key "user_group_converts", "user_groups"
  add_foreign_key "user_group_converts", "users"
  add_foreign_key "user_group_manual_values", "user_groups"
  add_foreign_key "user_logins", "users"
  add_foreign_key "watchdog_elements", "users"
end
