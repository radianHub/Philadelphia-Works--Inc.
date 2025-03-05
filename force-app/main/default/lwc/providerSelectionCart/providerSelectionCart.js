import { LightningElement, api } from 'lwc';

// TODO: Make mobile-friendly
// TODO: style ready text message
export default class ProviderSelectionCart extends LightningElement {
	@api selectedProviders;
	@api headerStyle;
	@api isDisabled;
	@api selectedProvidersCount;
	@api embedded; // If true, the cart is embedded in an accordion containing title & CTA

	get canProceed() {
		return !this.isDisabled;
	}

	get standalone() {
		return !this.embedded;
	}

	handleRemove(evt) {
		const providerId = evt.target.dataset.id;
		const event = new CustomEvent('removeprovider', {
			detail: { providerId: providerId },
			bubbles: true,
			composed: true,
		});
		this.dispatchEvent(event);
	}

    handleMoveUp(evt) {
        const providerId = evt.target.dataset.id;
		const event = new CustomEvent('moveup', {
			detail: { providerId: providerId },
			bubbles: true,
			composed: true,
		});
		this.dispatchEvent(event);
    }

    handleMoveDown(evt) {
        const providerId = evt.target.dataset.id;
        const event = new CustomEvent('movedown', {
            detail: { providerId: providerId },
			bubbles: true,
			composed: true,
        });
        this.dispatchEvent(event);
    }
}