require 'spec_helper'

describe Api::GroupsController do
  include SessionsHelper
  
  let(:user) { FactoryGirl.create :user }
  let(:user_2) { FactoryGirl.create :user, email: 'mcgonagol@hogwarts.com' }
  
  describe '#show' do
    let(:group) { FactoryGirl.create :group, users: [user_2] }

    context 'when the group exists' do
      let(:expected_json) do
        { 
          group: {
            id: group.id,
            name: group.name,
            user_ids: [user_2.id, user.id]
          }
        }.to_json
      end

      context 'and the group is owned by the current user' do
        before do
          user.groups << group
          sign_in user
          get :show, id: group.id
        end

        it 'should return status 200' do
          expect(response.status).to eq(200)
        end

        it 'should return the group serialized json' do
          expect(response.body).to eq(expected_json)
        end 
      end

      context 'and the group is NOT owned by the current user' do
        before do
          sign_in user
          get :show, id: group.id
        end

        it 'should return 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'and the user is not logged in' do
        before { get :show, id: group.id }

        it 'should return 404' do
          expect(response.status).to eq(404)
        end
      end
    end

    context 'when the group does not exist' do
      before do
        sign_in user
        get :show, id: 1
      end

      it 'should return a 404' do
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#create' do
    context 'with valid data' do
      let(:group_attrs) { FactoryGirl.attributes_for :group }

      context 'and when signed in' do
        before do
          sign_in user
          post :create, group: group_attrs
        end

        it 'should create a Group' do
          expect(Group.count).to eq(1)
        end

        it 'should redirect to show' do
          expect(response).to redirect_to(api_group_path(Group.first))
        end
      end

      context 'when not signed in' do
        before { post :create, group: group_attrs }

        it 'should return 403' do
          expect(response.status).to eq(403)
        end
      end
    end

    context 'with invalid data' do
      let(:group_attrs) { { name: '   ' } }

      before do
        sign_in user
        post :create, group: group_attrs
      end

      it 'should return 400' do
        expect(response.status).to eq(400)
      end

      it 'should not create a group' do
        expect(Group.count).to eq(0)
      end

      it 'should return errors' do
        expect(JSON.parse(response.body)['errors'].length > 0).to be_true
      end
    end
  end

  describe '#update' do
    let!(:group) { FactoryGirl.create :group, users: [user] }

    context 'with valid data' do
      let(:updates) do
        {
          name: 'Yolo Circus',
          user_ids: [user.id, user_2.id]
        }
      end

      context 'when signed in as the proper user' do
        before do
          sign_in user
          put :update, id: group.id, group: updates
          group.reload
        end

        it 'should return redirect to the group api path' do
          expect(response).to redirect_to(api_group_path(group))
        end

        it 'should update the group' do
          expect(group.name).to eq('Yolo Circus')
        end
      end

      context 'when signed in as a user who isnt part of the group' do
        before do
          sign_in user_2
          put :update, id: group.id, group: updates
          group.reload
        end

        it 'should return 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'when not signed in' do
        before { put :update, id: group.id, group: updates }

        it 'should return 404' do
          expect(response.status).to eq(404)
        end
      end
    end

    context 'with invalid data' do
      let(:updates) do
        {
          name: '   ',
          user_ids: [user.id, user_2.id]
        }
      end
      before do
        sign_in user
        put :update, id: group.id, group: updates
        group.reload
      end

      it 'should return 400' do
        expect(response.status).to eq(400)
      end

      it 'should return the errors' do
        expect(JSON.parse(response.body)['errors'].length > 0).to be_true
      end

      it 'should not update the group' do
        expect(group.name).not_to eq(updates[:name])
      end
    end
  end
end