module MotifCategory::Sortable
  CHRONOLOGICALLY_SORTED_CATEGORIES_SHORT_NAMES = %w[
    rsa_integration_information
    rsa_droits_devoirs
    rsa_orientation
    rsa_orientation_file_active
    rsa_orientation_france_travail
    rsa_orientation_coaching
    rsa_orientation_freelance
    rsa_orientation_on_phone_platform
    rsa_accompagnement
    rsa_accompagnement_social
    rsa_accompagnement_sociopro
    rsa_accompagnement_moins_de_30_ans
    rsa_follow_up
    rsa_cer_signature
    rsa_insertion_offer
    rsa_atelier_competences
    rsa_atelier_rencontres_pro
    rsa_atelier_collectif_mandatory
    rsa_main_tendue
    rsa_spie
    siae_interview
    siae_collective_information
    siae_follow_up
  ].freeze

  def position
    CHRONOLOGICALLY_SORTED_CATEGORIES_SHORT_NAMES.index(short_name) ||
      (CHRONOLOGICALLY_SORTED_CATEGORIES_SHORT_NAMES.length + 1)
  end
end
