import { LightningElement, api } from 'lwc';
import { seed } from './seed.js';

// TODO: Consume data from another source in a specific format
// TODO: Make modal fields configurable based on field set
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
 *          description: '<p><strong>Description:</strong> Provider 1 Description</p>',
 *      }
 * ]
 */
export default class ProviderMap extends LightningElement {
	@api providers;
	markers = seed;
	selectedMarkerValue;

	connectedCallback() {
		console.log('markers', JSON.parse(JSON.stringify(this.markers)));
		this.markers.push({
			location: {
				City: 'Philadelphia',
				Country: 'USA',
				State: 'PA',
				Street: '2910 South Street',
			},
			type: 'Circle',
			radius: 1609,
			strokeColor: '#FFF000',
			strokeOpacity: 0.8,
			strokeWeight: 2,
			fillColor: '#FFF000',
			fillOpacity: 0.35,
		});
	}

	handleMarkerSelect(evt) {
		console.log('handleMarkerSelect', evt.target);
		this.selectedMarkerValue = evt.target.selectedMarkerValue;
	}

	handleView(evt) {
		console.log('handleView: ', evt.target);
		this.selectedMarkerValue = evt.target.value;

		const map = this.template.querySelector('lightning-map');
		map.selectMarker(evt.target.value);
		console.log('map', map);
		const markerSelectEvent = new CustomEvent('markerselect', {
			bubbles: true,
			composed: true,
			detail: {
				selectedMarkerValue: this.selectedMarkerValue,
			},
		});
		this.dispatchEvent(markerSelectEvent);
	}
}
