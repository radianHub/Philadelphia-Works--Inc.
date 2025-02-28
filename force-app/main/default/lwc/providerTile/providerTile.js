import { LightningElement, api } from 'lwc';

/**
 * Provider Tile
 * @param title {String} - Title of the provider
 * @param subtitle {String} - Subtitle of the provider
 * @param description {String} - Description of the provider
 * @param details {[String]} - Details of the provider
 * @param cardHeaderColor {String} - Color of the card header
 * @param cardBodyColor {String} - Color of the card body
 * @example <c-provider-tile title={title} subtitle={subtitle} description={description} details={details} card-header-color={cardHeaderColor} card-body-color={cardBodyColor}></c-provider-tile>
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
	@api jobId;
	@api title;
    @api subtitle;
	@api description;
	@api address
	@api details;
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
}