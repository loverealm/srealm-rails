class DefaultLikeIntoLoveForContents < ActiveRecord::Migration
  def change
    ActsAsVotable::Vote.where(votable_type: 'Content', vote_scope: nil).update_all(vote_scope: 'love')
  end
end
