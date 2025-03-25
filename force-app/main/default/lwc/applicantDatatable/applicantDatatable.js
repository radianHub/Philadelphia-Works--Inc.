import LightningDatatable from 'lightning/datatable';
import customApplicantNameTemplate from './customApplicantName.html';

export default class ApplicantDatatable extends LightningDatatable {
	static customTypes = {
		customApplicantName: {
			template: customApplicantNameTemplate,
			standardCellLayout: true,
			typeAttributes: ['applicantName', 'isPriority', 'programName', 'rank', 'stage'],
		},
	};
}