FactoryBot.modify do
  factory :miq_request do
    trait :with_api_user do
      requester { User.find_by(:name=>"API User") }
    end
  end

  factory :miq_request_task do
    trait :with_api_user do
      userid { User.find_by(:name=>"API User").userid }
    end
  end

  factory :service_order do
    trait :with_api_user do
      user { User.find_by(:name=>"API User") }
    end
  end

  factory :service_template do
    trait :with_api_user
  end
end
