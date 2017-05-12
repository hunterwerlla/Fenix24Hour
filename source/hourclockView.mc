using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;
using Toybox.ActivityMonitor as AM;

class hourclockView extends Ui.WatchFace {

    var font;
    var isAwake;
    var screenShape;
    var dndIcon;
    var hrIcon;
    var hr;
    var phoneIcon;
    var batteryOutline;
    var notificationIcon;
    var batt;

    function initialize() {
        WatchFace.initialize();
        screenShape = Sys.getDeviceSettings().screenShape;
        hr = 0;
    }

    function onLayout(dc) {
    	hrIcon = Ui.loadResource(Rez.Drawables.HeartRateIcon);
    	batteryOutline = Ui.loadResource(Rez.Drawables.BatteryOutline);
        font = Ui.loadResource(Rez.Fonts.id_font_helvetica);
        if (Sys.getDeviceSettings() has :doNotDisturb) {
            dndIcon = Ui.loadResource(Rez.Drawables.DoNotDisturbIcon);
        } else {
            dndIcon = null;
        }
        if (Sys.getDeviceSettings() has :phoneConnected) {
            phoneIcon = Ui.loadResource(Rez.Drawables.BluetoothIcon);
        } else {
            phoneIcon = null;
        }
        if (Sys.getDeviceSettings() has :phoneConnected) {
            notificationIcon = Ui.loadResource(Rez.Drawables.NotificationIcon);
        } else {
            notificationIcon = null;
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

   function drawHand(dc, angle, length, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2),0], [-(width / 2), -length], [width / 2, -length], [width / 2, 0]];
        var result = new [4];
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [centerX + x, centerY + y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
        dc.fillPolygon(result);
    }

    // Draw the hash mark symbols on the watch
    // @param dc Device context
    function drawHashMarks(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
            var sX, sY;
            var eX, eY;
            var outerRad = width / 2;
            var innerRad = outerRad - 10;
            // Loop through each hour block
            for (var i = Math.PI / 12; i <= 2 * Math.PI; i += (Math.PI / 12)) {
                sY = outerRad + innerRad * Math.sin(i);
                eY = outerRad + outerRad * Math.sin(i);
                sX = outerRad + innerRad * Math.cos(i);
                eX = outerRad + outerRad * Math.cos(i);
                dc.drawLine(sX, sY, eX, eY);
            }
            //draw thicker lines for top marks related to minutes
            //unrolling loops makes me cool right guys
            dc.drawRectangle(dc.getWidth()/2-2, dc.getHeight()-12, 4, 12);
            dc.fillRectangle(dc.getWidth()/2-2, dc.getHeight()-12, 4, 12);
            dc.drawRectangle(dc.getWidth()-12, dc.getHeight()/2-2 , 12, 4);
            dc.fillRectangle(dc.getWidth()-12, dc.getHeight()/2-2, 12, 4);
            dc.drawRectangle(dc.getWidth()/2-2, 0 , 4, 12);
            dc.fillRectangle(dc.getWidth()/2-2, 0, 4, 12);
            dc.drawRectangle(0, dc.getHeight()/2-2 , 12, 4);
            dc.fillRectangle(0, dc.getHeight()/2-2, 12, 4);
    }

    // Handle the update event
    function onUpdate(dc) {
        var width;
        var height;
        var screenWidth = dc.getWidth();
        var clockTime = Sys.getClockTime();
        var hourHand;
        var minuteHand;

        width = dc.getWidth();
        height = dc.getHeight();

        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);

        var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);
        // Clear the screen
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Draw the background
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
        dc.fillPolygon([[0, 0], [dc.getWidth(), 0], [dc.getWidth(), dc.getHeight()], [0, 0]]);
        //change the color
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);

        // Draw the hash marks
        drawHashMarks(dc);

        // dc.drawBitmap( width * 0.75, height / 2 - 15, dndIcon);

        // Draw the hour. Convert it to minutes and compute the angle.
        //if snap hours is true, don't move based on minute
        hourHand = null;
        if(Application.getApp().getProperty("snapHours")){
        	hourHand = (((clockTime.hour % 24) * 60));
        } else {
        	hourHand = (((clockTime.hour % 24) * 60) + clockTime.min);
        }
        hourHand = hourHand / (24 * 60.0);
        hourHand = hourHand * Math.PI * 2;
        drawHand(dc, hourHand, 75, 8);

        // Draw the minute
        minuteHand = (clockTime.min / 60.0) * Math.PI * 2;
        drawHand(dc, minuteHand, 90, 4);
		
        // Draw the second if turned on
        if(Application.getApp().getProperty("secondsHand")) {
	        if (isAwake) {
	            dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
	            var sh = (clockTime.sec / 60.0) * Math.PI * 2;
	            var st = sh - Math.PI;
	            drawHand(dc, sh, 75, 2);
	            drawHand(dc, st, 15, 2);
	        }
        }

        // Draw the arbor
        dc.setColor( Gfx.COLOR_DK_GRAY , Gfx.COLOR_TRANSPARENT );
        dc.drawCircle(width / 2, height / 2, 6);
        dc.fillCircle(width / 2, height / 2, 6);

        
        //draw the digital time
        if(Application.getApp().getProperty("digitalTime")){
        	dc.drawText(width / 2, (height / 2)-37, Gfx.FONT_MEDIUM, clockTime.min ,  Gfx.TEXT_JUSTIFY_CENTER);
        	// Draw the date
        	dc.drawText(width / 2, (height / 4)-4, Gfx.FONT_MEDIUM, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
		} else {
			// Draw the date lower
        	dc.drawText(width / 2, (height / 2)-37, Gfx.FONT_MEDIUM, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
		}
		//draw the HR icon
		var tmphr = null;
		if(AM has :getHeartRateHistory){
			var tmphrHist =  AM.getHeartRateHistory(1, true);
			tmphr = tmphrHist.next().heartRate;
		} 
		//only draw heart rate if valid, otherwise don't even draw icon
		if (tmphr != null && tmphr < 250) {
			hr = tmphr;
			var hrIconOffset = 0;
			if(hr < 100){
				hrIconOffset = width / 2 -38;
			} else {
				hrIconOffset = width / 2 -40;
			}
			dc.drawText(width / 2-12, (height / 2)+20, Gfx.FONT_XTINY, hr, Gfx.TEXT_JUSTIFY_CENTER);
			dc.drawBitmap(hrIconOffset,(height / 2)+28,hrIcon);
		}
		
		var battery = Sys.getSystemStats().battery.toLong();
		//draw the battery outline, if applicable
		if(Application.getApp().getProperty("batteryOutline")) {
			dc.drawBitmap(width / 2+6, (height / 2)+22, batteryOutline);
		} else {
			battery += "%";
		}
		//draw the battery
		dc.drawText(width / 2 +22,(height / 2)+20, Gfx.FONT_XTINY, battery,  Gfx.TEXT_JUSTIFY_CENTER);
		//draw  event stuff
		if(dndIcon != null && Sys.getDeviceSettings().doNotDisturb){
			dc.drawBitmap(width / 2 +1,(height / 2)+50,dndIcon);
		}
		if(phoneIcon != null && Sys.getDeviceSettings().phoneConnected ){
			dc.drawBitmap(width / 2 -31,(height / 2)+50,phoneIcon);
		}
		if(notificationIcon != null && Sys.getDeviceSettings().notificationCount > 0 ){
			dc.drawBitmap(width / 2 -16,(height / 2)+50,notificationIcon);
		}
		// Draw the numbers
        dc.drawText(width / 2, 12, Gfx.FONT_XTINY , "00", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText((3*width/4)+13, 37, Gfx.FONT_XTINY, "03", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(width - 16, (height / 2) - 14, Gfx.FONT_XTINY, "06", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(3*width/4+17, 3*height/4-7, Gfx.FONT_XTINY, "09", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(width / 2, height - 37, Gfx.FONT_XTINY, "12", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 4-5, 3*height/4-7, Gfx.FONT_XTINY, "15", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(16, (height / 2) - 14, Gfx.FONT_XTINY, "18", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText((width/4)+5, 37, Gfx.FONT_XTINY, "21", Gfx.TEXT_JUSTIFY_RIGHT);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onEnterSleep() {
        isAwake = false;
        Ui.requestUpdate();
    }

    function onExitSleep() {
        isAwake = true;
    }
}
