import { LightningElement, api } from 'lwc';

// TODO: Make it possible to navigate to job tile from map details
/**
 * Displays a map of providers
 * @param providers {[Object]} - List of providers to display on the map
 * @example <c-provider-map providers={providers}></c-provider-map>
 * providers: [
 *     {
 * 			id: '1',
 *          title: 'Provider 1 Name',
 *          location: {
 *              City: 'Philadelphia',
 *              Country: 'USA',
 *              State: 'PA',
 *              Street: '2910 South Street',
 *              PostalCode: '19146',
 *          },
 *          details: [{
 * 				label: 'Ages Served',
 * 				value: '14, 15, 16'
 * 		    }]
 *      }
 * ]
 */
export default class ProviderMap extends LightningElement {
	_providers;
	@api get providers() {
		return this._providers;
	}
	set providers(value) {
		this._providers = JSON.parse(JSON.stringify(value)).map((provider) => {
			provider.description = provider.details
				.map((detail) => {
					return `<p><strong>${detail.label}</strong>: ${detail.value}</p>`;
				})
				.join('\n');
			return provider;
		});
	}
	selectedMarkerValue;

	handleMarkerSelect(evt) {
		this.selectedMarkerValue = evt.target.selectedMarkerValue;
	}

}