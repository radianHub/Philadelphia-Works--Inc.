/**
 * Created by holden on 3/20/25.
 */

import LightningDatatable from "lightning/datatable";
import customJobNameTemplate from "./customJobName.html";

export default class JobDatatable extends LightningDatatable {
    static customTypes = {
        customJobName: {
            template: customJobNameTemplate,
            standardCellLayout: true,
            typeAttributes: [ 'jobName', 'programName', 'supervisorName' ]
        }
    }
}