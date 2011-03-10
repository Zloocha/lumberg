require 'spec_helper'

module Lumberg
  describe Whm::Reseller do
    before(:each) do
      @login    = { :host => @whm_host, :hash => @whm_hash }
      @whm      = Whm::Server.new(@login.dup)
      @reseller = Whm::Reseller.new(:server => @whm)
    end

    describe "#setup_reseller" do
      use_vcr_cassette "whm/reseller/setupreseller"

      it "requires username" do
        requires_attr('username') { @reseller.create }
      end

      it "fails when the user doesn't exist" do
        result = @reseller.create(:username => 'invalid')
        result[:success].should be_false
        result[:message].should match(/does not exist/i)
      end

      it "creates a reseller" do
        result = @reseller.create(:username => 'bob')
        result[:success].should be_true
      end

      it "accepts makeowner option" do
        @reseller.server.should_receive(:perform_request).with('setupreseller', hash_including(:makeowner => true))
        @reseller.create(:username => 'bob', :makeowner => true)
      end
    end

    describe "#list" do
      use_vcr_cassette "whm/reseller/listresellers"

      it "lists all resellers" do
        result = @reseller.list
        result[:success].should be_true
        result[:params][:resellers].should have(2).resellers
        result[:params][:resellers].should include('bob', 'ted')
      end
    end 

    describe "#setresellerips" do
      use_vcr_cassette "whm/reseller/setresellerips"

      it "requires a username" do
        requires_attr('username') { @reseller.add_ips }
      end

      it "adds the ip address to the reseller account" do
        result = @reseller.add_ips(:username => 'bob', :ips =>'192.168.0.18')
        result[:message].should match(/Successfully configured IP addresses delegation to reseller/i)
      end

      it "returns an error for invalid ip addresses" do
        result = @reseller.add_ips(:username => 'bob', :ips =>'127.0.0.1')
        result[:message].should match(/The list of supplied IP addresses contains inappropriate values/i)
      end
    end

    describe "#setresellerlimits" do
      use_vcr_cassette "whm/reseller/setresellerlimits"

      it "requires a username" do
        requires_attr('username') { @reseller.set_limits }
      end

      it "sets the limits" do
        result = @reseller.set_limits(:username => 'bob', :diskspace_limit => 1024, :enable_overselling => true, 
                                      :enable_overselling_diskspace => true)
        result[:success].should be_true
        result[:message].should match(/Successfully set reseller account .*limits/i)
      end
    end

    describe "#setresellermainip" do
      use_vcr_cassette "whm/reseller/setresellermainip"

      it "requires a username" do
        requires_attr('username') { @reseller.set_main_ip(:ip => '127.0.0.1') }
      end

      it "requires an ip" do
        requires_attr('ip') { @reseller.set_main_ip(:username => 'bob') }
      end

      it "sets the main ip" do
        result = @reseller.set_main_ip(:username => 'bob', :ip => '192.168.0.18')
        result[:success].should be_true
        result[:message].should match(/Successfully set main IP address of the reseller/i)
      end

      it "returns an error when the IP is invalid" do
        result = @reseller.set_main_ip(:username => 'bob', :ip => '10')
        result[:success].should be_false
        result[:message].should match(/Supplied IP address is invalid/)
      end

      it "returns an error when the user is invalid" do
        result = @reseller.set_main_ip(:username => 'notexists', :ip => '127.0.0.1')
        result[:success].should be_false
        result[:message].should match(/Specified user is not a reseller/i)
      end
    end
  end
end
