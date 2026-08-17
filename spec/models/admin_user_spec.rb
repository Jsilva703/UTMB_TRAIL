require "rails_helper"

RSpec.describe AdminUser, type: :model do
  it "authenticates with a valid password" do
    admin_user = AdminUser.create!(email: "Admin@Example.com", password: "password123")

    expect(described_class.authenticate("admin@example.com", "password123")).to eq(admin_user)
    expect(admin_user.reload.email).to eq("admin@example.com")
    expect(admin_user.password_digest).not_to eq("password123")
  end

  it "does not authenticate with an invalid password" do
    AdminUser.create!(email: "admin@example.com", password: "password123")

    expect(described_class.authenticate("admin@example.com", "wrong")).to be_nil
  end

  it "does not authenticate inactive admins" do
    AdminUser.create!(email: "admin@example.com", password: "password123", active: false)

    expect(described_class.authenticate("admin@example.com", "password123")).to be_nil
  end

  it "requires unique normalized email" do
    AdminUser.create!(email: "admin@example.com", password: "password123")
    duplicate = AdminUser.new(email: " ADMIN@example.com ", password: "password123")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end
end
