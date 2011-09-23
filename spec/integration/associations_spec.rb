require 'spec_helper'

describe "associations" do
  with_connection do
    before :all do
      class ::User
        include DataMapper::Mongo::Resource

        property :id, ObjectId
        property :group_id, ForeignObjectId
        property :name, String
        property :age, Integer
      end

      class ::Group
        include DataMapper::Mongo::Resource

        property :id, ObjectId
        property :name, String
      end

      class ::Friend
        include DataMapper::Mongo::Resource

        property :id, ObjectId
        property :name, String
      end

      User.belongs_to :group
      Group.has Group.n, :users
      User.has User.n, :friends
      DataMapper.finalize
    end

    before :each do
      reset_db
    end

    describe "belongs_to" do
      before do
        @john = User.create_or_raise(:name => 'john', :age => 101)
        @jane = User.create_or_raise(:name => 'jane', :age => 102)

        @group = Group.create_or_raise(:name => 'dm hackers')
      end

      it "should set parent object _id in the db ref" do
        lambda {
          @john.group = @group
          @john.save
        }.should_not raise_error

        @john.group_id.should eql(@group.id)
      end

      it "should fetch parent object" do
        user = User.create_or_raise(:name => 'jane')
        user.group_id = @group.id
        user.group.should eql(@group)
      end

      it "should work with SEL" do
        users = User.all(:name => /john|jane/)

        users.each { |u| u.update(:group_id => @group.id) }

        users.each do |user|
          user.group.should_not be_nil
        end
      end
    end

    describe "has many" do
###    before :each do
###      @john = User.create_or_raise(:name => 'john', :age => 101)
###      @jane = User.create_or_raise(:name => 'jane', :age => 102)
###
###      @group = Group.create_or_raise(:name => 'dm hackers')
###
###      [@john, @jane].each { |user| user.update(:group_id => @group.id) }
###    end

      # @done
      it "should get children" do
        pending "bug in edge dm-core causes an infinite loop here" do
          @group.users.size.should eql(2)
        end
      end

      it "should add new children with <<" do
        pending "bug in edge dm-core causes an infinite loop here" do
          user = User.new(:name => 'kyle')
          @group.users << user
          user.group_id.should eql(@group.id)
          @group.users.size.should eql(3)
        end
      end

      # @done
      it "should replace children" do
        pending "bug in edge dm-core causes an infinite loop here" do
          user = User.create_or_raise(:name => 'stan')
          @group.users = [user]
          @group.users.size.should eql(1)
          @group.users.first.should eql(user)
        end
      end

      it "should fetch children matching conditions" do
        pending "bug in edge dm-core causes an infinite loop here" do
          users = @group.users.all(:name => 'john')
          users.size.should eql(1)
        end
      end
    end

    describe "nested saves" do
      before :each do
        #@friend1 = Friend.new
        #@friend2 = Friend.new
        @user1 = User.new
        @user2 = User.new
        @group = Group.new(:users =>
            [
            {:friends =>
                [{:name => "blah"}, {:name => "blah2"}]
            },
            {:friends =>
                [{:name => "blah3"},{:name => "blah4"}]
            }])
      end

      # @done
      it "should save nested objects" do

        #@group.users << @user1
        #@group.users << @user2
        @group.save
        Group.get(@group.id).users.all.each do |u|
          u.group_id.should == @group.id
          u.friends.each do |f|
            f.user_id.should == u.id
          end
        end
      end
    end
  end
end
