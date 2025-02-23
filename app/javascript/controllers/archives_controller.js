import { Controller } from "@hotwired/stimulus";
import Swal from "sweetalert2";
import createArchive from "../react/actions/createArchive";
import deleteArchive from "../react/actions/deleteArchive";

export default class extends Controller {
  connect() {
    this.applicantId = this.element.dataset.applicantId;
    this.organisationId = this.element.dataset.organisationId;
    this.departmentId = this.element.dataset.departmentId;
    this.archiveId = this.element.dataset.archiveId;
    this.navigationLevel = this.element.dataset.navigationLevel;
  }

  async create() {
    const { value: archiveReason, isConfirmed } = await Swal.fire({
      icon: "warning",
      title: "Le dossier sera archivé sur toutes les organisations",
      text: "Si des invitations envoyées au bénéificiaire sont toujours valides, il ne pourra plus les utiliser pour prendre rendez-vous",
      input: "text",
      inputLabel: "Motif d'archivage:",
      showCancelButton: true,
      allowHTML: true,
      confirmButtonText: "Oui",
      cancelButtonText: "Annuler",
      confirmButtonColor: "#EC4C4C",
      cancelButtonColor: "#083b66",
    });

    if (isConfirmed) {
      const attributes = {
        archiving_reason: archiveReason,
        applicant_id: this.applicantId,
        department_id: this.departmentId,
      };

      const result = await createArchive(attributes);
      this.handleResult(result);
    }
  }

  async destroy() {
    const { isConfirmed } = await Swal.fire({
      title: "Le dossier sera rouvert",
      text: "Le dossier retrouvera le statut précédant l'archivage",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Oui",
      cancelButtonText: "Annuler",
      confirmButtonColor: "#EC4C4C",
      cancelButtonColor: "#083b66",
    });

    if (isConfirmed) {
      const result = await deleteArchive(this.archiveId);
      this.handleResult(result);
    }
  }

  handleResult(result) {
    if (result.success) {
      if (this.navigationLevel === "department") {
        window.location.replace(`/departments/${this.departmentId}/applicants/${this.applicantId}`);
      } else {
        window.location.replace(
          `/organisations/${this.organisationId}/applicants/${this.applicantId}`
        );
      }
    } else {
      Swal.fire("Impossible d'archiver le dossier", result.errors[0], "error");
    }
  }
}
