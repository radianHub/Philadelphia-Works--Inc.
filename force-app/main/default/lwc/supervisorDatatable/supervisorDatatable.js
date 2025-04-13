import LightningDatatable from 'lightning/datatable';
import customSupervisorNameTemplate from './customSupervisorName.html';

export default class SupervisorDatatable extends LightningDatatable {
	static customTypes = {
		customSupervisorName: {
			template: customSupervisorNameTemplate,
			standardCellLayout: true,
			typeAttributes: ['supervisorName', 'supervisorClearance'],
		},
	};
}