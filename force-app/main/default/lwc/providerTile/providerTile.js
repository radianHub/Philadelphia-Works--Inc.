import { LightningElement, api } from 'lwc';

// TODO: move subtitle to body of card
/**
 * Provider Tile
 * @param provider {Object} - Provider
 * @param cardHeaderColor {String} - Color of the card header
 * @param cardBodyColor {String} - Color of the card body
 * @param showApply {Boolean} - Show apply button
 * @example <c-provider-tile provider={provider} card-header-color={cardHeaderColor} card-body-color={cardBodyColor} showApply={showApply}></c-provider-tile>
 * details: [
 *      {
 *          label: 'Ages Served',
 *          value: '12, 13, 14'
 *      }, {
 *          label: 'Interest Areas',
 *          value: 'STEM, Arts'
 *      }
 * ]
 */
export default class ProviderTile extends LightningElement {
	@api provider;
	@api cardHeaderColor;
	@api cardBodyBgColor;
	@api showApply;
    showFullDescription = false;

	get cardStyle() {
		return this.cardBodyBgColor
			? '--slds-c-card-color-background:' + this.cardBodyBgColor
			: '--slds-c-card-color-background:rgb(235, 235, 235)';
	}

	get cardHeaderStyle() {
		return this.cardHeaderColor ? 'color:' + this.cardHeaderColor : 'color:rgb(84, 105, 141)';
	}

    get descriptionClass() {
        return this.showFullDescription ? '' : 'slds-line-clamp';
    }

    get descriptionLabel() {
        return this.showFullDescription ? 'View Less' : 'View More';
    }

    toggleDescription() {
        this.showFullDescription = !this.showFullDescription;
    }

	handleAdd() {
		const event = new CustomEvent('selectprovider', {
			detail: { providerId: this.provider.id }
		});
		this.dispatchEvent(event);
	}

	handleRemove() {
		const event = new CustomEvent('removeprovider', {
			detail: { providerId: this.provider.id }
		});
		this.dispatchEvent(event);
	}
}