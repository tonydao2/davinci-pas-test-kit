module DaVinciPASTestKit
  module DaVinciPASV221
    module ServerReplacedPAValidation

      AUTHORIZATION_NUMBER_EXTENSION =
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-authorizationNumber'
      ADMINISTRATION_REFERENCE_NUMBER_EXTENSION =
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-administrationReferenceNumber'
      REFERENCE_EXTENSION_URLS = [
        AUTHORIZATION_NUMBER_EXTENSION,
        ADMINISTRATION_REFERENCE_NUMBER_EXTENSION
      ].freeze

    end

    class PASServerClaimUpdateReplacedPAInquireTest < Inferno::Test
  
      id :pas_server_v221_claim_update_replaced_pa_inquire_test
      title 'Server supports an inquiry using a replaced PA reference number'
      description %(
        This test submits a PAS `$inquire` request containing a REF-NT or REF-BB
        reference number from a prior authorization that has since been replaced.
        It verifies that the server returns an authorization response with a
        different reference number.
      )

      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-47'

      input :replaced_pa_inquire_request_payload,
            title: 'PAS $inquire Request for a Replaced PA',
            description: %(
              Provide a PAS Inquiry Request Bundle containing a replaced REF-NT
              or REF-BB reference number.
            ),
            type: 'textarea',
            optional: true

      input_order :replaced_pa_inquire_request_payload, :server_endpoint, :smart_credentials

      config options: {
        ig_version: 'v2.2.1',
        use_case: 'replaced prior authorization',
        request_tag: REPLACED_PA_INQUIRE_TAG
      }

      run do
        request = 
        assert request.present?, 'No replaced PA inquiry request was performed.'

        submitted_references = request_references(request)
        assert submitted_references.values.flatten.present?,
               'The inquiry request did not contain a REF-NT or REF-BB reference number.'

        returned_references = response_references(request)
        assert returned_references.values.flatten.present?,
               'The inquiry response did not contain a ClaimResponse with a REF-NT or REF-BB reference number.'

        different_reference_returned = REFERENCE_EXTENSION_URLS.any? do |extension_url|
          submitted = submitted_references[extension_url]
          returned = returned_references[extension_url]
          submitted.present? && returned.any? { |reference| submitted.exclude?(reference) }
        end

        assert different_reference_returned,
               'The inquiry response did not contain a current reference number different from the replaced ' \
               'reference number in the inquiry request.'
      end
    end
  end
end
