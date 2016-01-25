require 'spec_helper'

describe 'Test request', type: :request do
  fixtures :articles

  let(:authorizations) { {} }
  let(:policy_scope) { Article.none }

  subject { last_response }
  let(:json_data) { JSON.parse(last_response.body)["data"] }

  before do
    authorizations.each do |action, retval|
      allow_any_instance_of(ArticlePolicy).to receive("#{action}?").and_return(retval)
    end
    allow_any_instance_of(ArticlePolicy::Scope).to receive(:resolve).and_return(policy_scope)
  end

  describe 'GET /articles' do
    before { get('/articles') }

    context 'unauthorized for index?' do
      let(:authorizations) { {index: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for index?' do
      let(:authorizations) { {index: true} }
      let(:policy_scope) { Article.where(id: Article.first.id) }

      it { is_expected.to be_ok }

      it 'returns results limited by policy scope' do
        expect(json_data.length).to eq(1)
        expect(json_data.first["id"]).to eq(Article.first.id.to_s)
      end
    end
  end

  describe 'GET /articles/:id' do
    before { get("/articles/#{Article.first.id}") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show?' do
      let(:authorizations) { {show: false} }

      context 'not limited by policy scope' do
        it { is_expected.to be_forbidden }
      end

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: Article.first.id) }
        it { is_expected.to be_not_found }
      end
    end

    context 'authorized for show?' do
      let(:authorizations) { {show: true} }
      it { is_expected.to be_ok }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: Article.first.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'GET /articles/:id/relationships', pending: 'relationships not yet implemented' do
    before { get("/articles/#{Article.first.id}/relationships") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show?' do
      let(:authorizations) { {show: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show?' do
      let(:authorizations) { {show: true} }
      it { is_expected.to be_ok }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: Article.first.id) }
        it { is_expected.to be_not_found }
      end

      xit 'displays only relationships allowed by policies'
    end
  end

  describe 'GET /articles/:id/comments', pending: true do
    before { get("/articles/#{Article.first.id}/comments") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show?' do
      let(:authorizations) { {show: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show?' do
      let(:authorizations) { {show: true} }
      it { is_expected.to be_ok }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: Article.first.id) }
        it { is_expected.to be_not_found }
      end

      xit 'displays only comments allowed by CommentPolicy::Scope'
    end
  end

  describe 'GET /articles/:id/author', pending: true do
    before { get("/articles/#{Article.first.id}/author") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show?' do
      let(:authorizations) { {show: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show?' do
      let(:authorizations) { {show: true} }
      it { is_expected.to be_ok }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: Article.first.id) }
        it { is_expected.to be_not_found }
      end

      context 'unauthorized for show? on author record' do
        it { is_expected.to be_forbidden }
      end
    end
  end

  describe 'POST /articles', pending: true do
    before { post("/articles", '{ "data": { "type": "articles" } }') }

    context 'unauthorized for create?' do
      let(:authorizations) { {create: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for create?' do
      let(:authorizations) { {create: true} }
      it { is_expected.to be_created }
    end
  end

  describe 'POST /articles/:id/relationships/comments', pending: true do
    context 'unauthorized for update? on article' do
      let(:authorizations) { {update: false} }

      xcontext 'unauthorized for update? on comment' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on comment' do
        # This is a tricky one. In real life, this is often something you may
        # want to permit. However, it is difficult to model with the typical
        # Pundit actions without knowing the particular use case

        it { is_expected.to be_forbidden }
      end
    end

    context 'authorized for update? on article' do
      let(:authorizations) { {update: true} }

      xcontext 'unauthorized for update? on comment' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on comment' do
        it { is_expected.to be_created }
      end
    end
  end

  describe 'PATCH /articles/:id/relationships/author' do
    context 'unauthorized for update? on article' do
      let(:authorizations) { {update: false} }

      xcontext 'unauthorized for update? on author' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on author' do
        it { is_expected.to be_forbidden }
      end
    end

    context 'authorized for update? on article' do
      let(:authorizations) { {update: true} }

      xcontext 'unauthorized for update? on author' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on author' do
        it { is_expected.to be_created }
      end
    end
  end

  describe 'DELETE /articles/:id/relationships/comments' do
    context 'unauthorized for update? on article' do
      let(:authorizations) { {update: false} }

      xcontext 'unauthorized for update? on any of the comments' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on all the comments' do
        it { is_expected.to be_forbidden }
      end
    end

    context 'authorized for update? on article' do
      let(:authorizations) { {update: true} }

      xcontext 'unauthorized for update? on any of the comments' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on all the comments' do
        it { is_expected.to be_successful }
      end
    end
  end

  describe 'DELETE /articles/:id' do
    before { delete("/articles/#{Article.first.id}") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for destroy?' do
      let(:authorizations) { {destroy: false} }

      context 'not limited by policy scope' do
        it { is_expected.to be_forbidden }
      end

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: Article.first.id) }
        it { is_expected.to be_not_found }
      end
    end

    context 'authorized for destroy?' do
      let(:authorizations) { {destroy: true} }
      it { is_expected.to be_successful }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: Article.first.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  ## --- Tricky cases ---

  describe 'GET /articles/:id?includes=comments' do
    before { get("/articles/#{Article.first.id}?includes=comments") }
    let(:policy_scope) { Article.all }

    context 'authorized for show?' do
      let(:authorizations) { {show: true} }

      xit 'displays only comments allowed by CommentPolicy::Scope'
    end
  end

  describe 'POST /comments (with relationships link to articles)', pending: true do
    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": {
          "type": "comments",
          "relationships": {
            "article": {
              "data": {
                "id": "1",
                "type": "articles"
              }
            }
          }
        }
      }
      EOS
    end

    context 'unauthorized for update? on article' do
      let(:authorizations) { {update: false} }

      xcontext 'authorized for create? on comment' do
        # This is a tricky one. In real life, this is often something you may
        # want to permit. However, it is difficult to model with the typical
        # Pundit actions without knowing the particular use case

        it { is_expected.to be_forbidden }
      end
    end
  end

  describe 'PATCH /articles/:id (mass-modifying relationships)', pending: true do
    let(:existing) do
      Article.new(comments: Comment.where(id: 3))
    end

    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": {
          "id": "<<TODO>>"
          "type": "articles",
          "relationships": {
            "comments": {
              "data": [
                { "type": "comments", "id": "1" },
                { "type": "comments", "id": "2" }
              ]
            }
          }
        }
      }
      EOS
    end

    context 'authorized for update? on article' do
      let(:authorizations) { {update: true} }

      xcontext 'unauthorized for update? on comment 3' do
        it { is_expected.to be_forbidden }
      end
      xcontext 'unauthorized for update? on comment 2' do
        it { is_expected.to be_forbidden }
      end
      xcontext 'unauthorized for update? on comment 1' do
        it { is_expected.to be_forbidden }
      end
      xcontext 'authorized for update? on comments 1,2,3' do
        it { is_expected.to be_successful }
      end
    end
  end
end