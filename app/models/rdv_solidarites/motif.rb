module RdvSolidarites
  class Motif < Base
    RECORD_ATTRIBUTES = [
      :id, :deleted_at, :location_type, :name, :reservable_online, :service_id, :category, :collectif
    ].freeze
    attr_reader(*RECORD_ATTRIBUTES)

    def presential?
      location_type == "public_office"
    end

    def name_with_location_type
      "#{name}-#{location_type}"
    end

    def to_rdv_insertion_attributes
      attributes.merge(rdv_solidarites_service_id: service_id)
    end
  end
end
