import { LightningElement, api } from "lwc";

export default class PjnMetricTiles extends LightningElement {
    @api items;

    handleTileClick(event) {
        this.dispatchEvent(
            new CustomEvent( "tileclicked", { detail: event.currentTarget.dataset.id } )
        );
    }
}