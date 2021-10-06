describe 'TasksController' do
  let(:task)    { FactoryBot.create(:miq_task, :state => MiqTask::STATE_FINISHED, :userid => "testuser") }
  let(:task2)   { FactoryBot.create(:miq_task, :state => MiqTask::STATE_FINISHED) }
  let(:my_task) { FactoryBot.create(:miq_task, :state => MiqTask::STATE_FINISHED, :userid => "api_user_id") }

  def expect_deleted(*args)
    args.each do |arg|
      expect(MiqTask.find_by(:id => arg.id)).to be_nil
    end
  end

  def expect_not_deleted(*args)
    expect(MiqTask.where(:id => args.collect(&:id)).length).to eq(args.length)
  end

  it 'will not delete other users tasks on DELETE when role is miq_task_my_ui' do
    api_basic_authorize 'miq_task_my_ui', resource_action_identifier(:tasks, :delete, :delete)
    delete(api_task_url(nil, task))
    expect_not_deleted(task)
  end

  it 'deletes on DELETE' do
    api_basic_authorize 'miq_task_all_ui', resource_action_identifier(:tasks, :delete, :delete)

    delete(api_task_url(nil, task))

    expect(response).to have_http_status(:no_content) # 204
    expect_deleted(task)
  end

  it 'will not delete other users tasks on POST when role is miq_task_my_ui' do
    api_basic_authorize 'miq_task_my_ui', resource_action_identifier(:tasks, :delete)
    data = {
      :action => 'delete'
    }
    post(api_task_url(nil, task), :params => data)
    expect_not_deleted(task)
  end

  it 'deletes on POST' do
    api_basic_authorize 'miq_task_all_ui', resource_action_identifier(:tasks, :delete)

    post(api_task_url(nil, task), :params => {:action => 'delete'})

    expect_deleted(task)
    expect_single_action_result(:success => true, :message => /Deleting Task/)
  end

  it 'bulk deletes' do
    api_basic_authorize 'miq_task_all_ui', collection_action_identifier(:tasks, :delete)

    data = {
      :action    => 'delete',
      :resources => [
        {:href => api_task_url(nil, task)},
        {:href => api_task_url(nil, task2)}
      ]
    }
    post(api_tasks_url, :params => data)

    expect(response).to have_http_status(:ok) # 200
    expect_deleted(task, task2)
    expect_multiple_action_result(2, :success => true, :message => /Deleting Task/)
  end

  describe 'GET /api/tasks' do
    it 'returns tasks with miq_tasks_all_ui role' do
      api_basic_authorize('miq_task_all_ui')

      get(api_tasks_url)

      expect(response).to have_http_status(:ok)
    end

    it 'returns tasks with miq_task_my_ui role' do
      api_basic_authorize('miq_task_my_ui')

      get(api_tasks_url)

      expect(response).to have_http_status(:ok)
    end

    it 'does not return tasks without an appropriate role' do
      api_basic_authorize

      get(api_tasks_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/tasks/:id' do
    it 'returns a task with miq_tasks_all_ui role' do
      api_basic_authorize('miq_task_all_ui')

      get(api_task_url(nil, task))

      expected = {
        'href' => api_task_url(nil, task),
        'name' => task.name
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'does not returns a task for other users when role is miq_task_my_ui' do
      api_basic_authorize('miq_task_my_ui')
      get(api_task_url(nil, task))
      expect(response.parsed_body["error"]["message"]).to include("Couldn't find MiqTask")
    end

    it 'returns a task miq_task_my_ui role' do
      api_basic_authorize('miq_task_my_ui')

      get(api_task_url(nil, my_task))

      expected = {
        'href' => api_task_url(nil, my_task),
        'name' => my_task.name
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'does not return a task without an appropriate role' do
      api_basic_authorize

      get(api_task_url(nil, task))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
