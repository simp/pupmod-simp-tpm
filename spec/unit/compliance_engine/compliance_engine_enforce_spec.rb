require 'spec_helper'

# This is the class that needs to be added to the catalog last to make the
# reporting work.
describe 'compliance_markup', type: :class do

  compliance_profiles = [
    'disa_stig',
    'nist_800_53',
    'nist_800_53_rev4'
  ]

  # A list of classes that we expect to be included for compliance
  #
  # This needs to be well defined since we can also manipulate defined type
  # defaults
  expected_classes = [
    'tpm'
  ]

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts){ os_facts }

      compliance_profiles.each do |target_profile|
        context "with compliance profile '#{target_profile}'" do
          let(:pre_condition) {%(
            #{expected_classes.map{|c| %{include #{c}}}.join("\n")}
          )}

          it { is_expected.to compile }

          let(:compliance_report) {
            JSON.load(
              catalogue.resource("File[#{facts[:puppet_vardir]}/compliance_report.json]")[:content]
            )
          }

          let(:compliance_profile_data) { compliance_report['compliance_profiles'][target_profile] }

          it 'should have a compliance profile report' do
            expect(compliance_profile_data).to_not be_nil
          end

          # The list of report sections that should not exist and if they do
          # exist, we need to know what is wrong so that we can fix them
          report_validators = [
            # This should *always* be empty on enforcement
            'non_compliant',
            # If something is set here, either the upstream API changed or you
            # have a typo in your data
            'documented_missing_parameters'
          ]

          report_validators.each do |report_section|
            it "should have no issues with the '#{report_section}' report" do
              if compliance_profile_data[report_section]
                # This just gets us a good print out of what went wrong
                expect(compliance_profile_data[report_section]).to eq({})
              else
                expect(compliance_profile_data[report_section]).to be_nil
              end
            end
          end
        end
      end
    end
  end
end
