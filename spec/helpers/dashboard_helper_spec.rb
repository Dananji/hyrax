require 'spec_helper'

describe DashboardHelper do
  
  describe "#render_recent_activity" do
    context "when there is no activity" do
      it "should return a messages stating the user has no recent activity" do
        assign(:activity, [])
        expect(helper.render_recent_activity).to include("no recent activity")
      end
    end
  end

  describe "#render_recent_notifications" do
    context "when there are no notifications" do
      it "should return a messages stating the user has no recent notifications" do
        assign(:notifications, [])
        expect(helper.render_recent_notifications).to include("no notifications")
      end
    end
  end

  describe "#on_the_dashboard?" do
    it "should return false for controllers that aren't a part of the dashboard" do
      allow(helper).to receive(:params).and_return({ controller: "foo" })
      expect(helper).to_not be_on_the_dashboard
    end

    it "should return true for controllers that are part of the dashboard" do
      allow(helper).to receive(:params).and_return({ controller: "my/files" })
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return({ controller: "my/collections" })
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return({ controller: "my/highlights" })
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return({ controller: "my/shares" })
      expect(helper).to be_on_the_dashboard
    end
  end

  describe "#on_my_files" do
    it "should return false when the controller isn't my files" do
      allow(helper).to receive(:params).and_return({ controller: "my/collections" })
      expect(helper).to_not be_on_my_files
    end
    it "should return true when the controller is my files" do
      allow(helper).to receive(:params).and_return({ controller: "my/files" })
      expect(helper).to be_on_my_files
    end
  end

end
