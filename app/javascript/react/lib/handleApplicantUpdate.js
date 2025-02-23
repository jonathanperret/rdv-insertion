import Swal from "sweetalert2";
import updateApplicant from "../actions/updateApplicant";

const handleApplicantUpdate = async (organisationId, applicant, attributes) => {
  const result = await updateApplicant(organisationId, applicant.id, attributes);
  if (result.success) {
    applicant.updateWith(result.applicant);
  } else {
    Swal.fire("Impossible de mettre à jour le bénéficiaire'", result.errors[0], "error");
  }
  return result;
};

export default handleApplicantUpdate;
