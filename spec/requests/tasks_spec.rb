describe 'TasksController' do
  let(:task) { FactoryGirl.create(:miq_task, :state => MiqTask::STATE_FINISHED) }
  let(:task2) { FactoryGirl.create(:miq_task, :state => MiqTask::STATE_FINISHED) }

  def expect_deleted(*args)
    args.each do |arg|
      expect(MiqTask.find_by(:id => arg.id)).to be_nil
    end
  end

  it 'deletes on DELETE' do
    api_basic_authorize resource_action_identifier(:tasks, :delete, :delete)

    delete(api_task_url(nil, task.id))

    expect(response).to have_http_status(:no_content) # 204
    expect_deleted(task)
  end

  it 'deletes on POST' do
    api_basic_authorize resource_action_identifier(:tasks, :delete)

    data = {
      :action => 'delete'
    }
    post(api_task_url(nil, task.id), :params => data)

    expect(response).to have_http_status(:ok) # 200
    expect_deleted(task)

    expected = {
      'success' => true,
      'message' => "tasks id: #{task.id} deleting"
    }
    expect(response.parsed_body).to include(expected)
  end

  it 'bulk deletes' do
    api_basic_authorize collection_action_identifier(:tasks, :delete)

    data = {
      :action    => 'delete',
      :resources => [
        {:href => api_task_url(nil, task.id)},
        {:href => api_task_url(nil, task2.id)}
      ]
    }
    post(api_tasks_url, :params => data)

    expect(response).to have_http_status(:ok) # 200
    expect_deleted(task, task2)

    expected = {
      'results' => a_collection_including(
        a_hash_including('success' => true, 'message' => "tasks id: #{task.id} deleting"),
        a_hash_including('success' => true, 'message' => "tasks id: #{task2.id} deleting")
      )
    }
    expect(response.parsed_body).to include(expected)
  end
end
