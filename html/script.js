$(function() {
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.action === "showControls") {
            $('#controls-container').removeClass('hidden');
            updatePositionValues(data.data.position);
            if (data.data.weaponType === "small") {
                $('#weapon-type-header').text('Weapon Position Adjustment (Small)');
            } else {
                $('#weapon-type-header').text('Weapon Position Adjustment (Large)');
            }
        } else if (data.action === "hideControls") {
            $('#controls-container').addClass('hidden');
        } else if (data.action === "updatePosition") {
            updatePositionValues(data.data.position);
        }
    });
    
    function updatePositionValues(position) {
        $('#pos-x').text(position.x.toFixed(3));
        $('#pos-y').text(position.y.toFixed(3));
        $('#pos-z').text(position.z.toFixed(3));
        $('#rot-pitch').text(position.pitch.toFixed(1));
        $('#rot-roll').text(position.roll.toFixed(1));
        $('#rot-yaw').text(position.yaw.toFixed(1));
    }
});
