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
    //var screenShape;
    var dndIcon;
    var hrIcon;
    var hr;
    var phoneIcon;
    var batteryOutline;
    var notificationIcon;
    var batt;

    function initialize() {
        WatchFace.initialize();
        //screenShape = Sys.getDeviceSettings().screenShape; //unused until make a square version
        hr = 0;
    }

    function onLayout(dc) {
        font = Ui.loadResource(Rez.Fonts.id_font_helvetica); //load font
        setupIcons(); //load icons
    }

	function setupIcons(){
		hrIcon = Ui.loadResource(Rez.Drawables.HeartRateIcon);
		batteryOutline = Ui.loadResource(Rez.Drawables.BatteryOutline);
	    if (Sys.getDeviceSettings() has :doNotDisturb) {
            dndIcon = Ui.loadResource(Rez.Drawables.DoNotDisturbIcon);
        } else {
            dndIcon = null;
        }
        if (Sys.getDeviceSettings() has :phoneConnected) {
            phoneIcon = Ui.loadResource(Rez.Drawables.BluetoothIcon);
            notificationIcon = Ui.loadResource(Rez.Drawables.NotificationIcon);
        } else {
            phoneIcon = null;
            notificationIcon = null;
        }
	}

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    
    }
    
	function onUpdate(dc) {
        var clockTime = Sys.getClockTime();
        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);
        var width = dc.getWidth();
        var height = dc.getHeight();

        drawBackground(dc);
        drawHashMarks(dc,width,height);
        drawHands(dc,width,height,clockTime);
		drawArbor(dc,width,height);
		drawDigitalTime(dc,width,height,clockTime);
		drawDate(dc,width,height,info);
		drawIndicators(dc,width,height);
		drawNumbers(dc,width,height);
    }
    
    function drawArbor(dc,width,height){
        dc.setColor( Gfx.COLOR_DK_GRAY , Gfx.COLOR_TRANSPARENT );
        dc.drawCircle(width / 2, height / 2, 6);
        dc.fillCircle(width / 2, height / 2, 6);
    }
    
    function drawDigitalTime(dc,width,height,clockTime){
    	dc.setColor( Gfx.COLOR_DK_GRAY , Gfx.COLOR_TRANSPARENT );
        if(Application.getApp().getProperty("@Properties.digitalTime")){
        	dc.drawText(width / 2, (height / 2)-37, Gfx.FONT_MEDIUM, clockTime.min, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }
    
    function drawDate(dc,width,height,info){
        dc.setColor( Gfx.COLOR_DK_GRAY , Gfx.COLOR_TRANSPARENT );
    	var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);
        if(Application.getApp().getProperty("@Properties.digitalTime")){
        	dc.drawText(width / 2, (height / 4)-4, Gfx.FONT_MEDIUM, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
		} else {// Draw the date lower
        	dc.drawText(width / 2, (height / 2)-37, Gfx.FONT_MEDIUM, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
		}
    }
    
    function drawHands(dc,height,width,clockTime){
    	//set color for hands
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    	drawHourHand(dc,height,width,clockTime);
    	drawMinuteHand(dc,height,width,clockTime);
    	//set color for seconds hand
    	dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
    	drawSecondsHand(dc,height,width,clockTime);
    }
    
    function drawHourHand(dc,height,width,clockTime){
    	//Convert it to minutes and compute the angle.
        //if snap hours is true, don't move based on minute
        var hourHand = null;
        if(Application.getApp().getProperty("@Properties.snapHours")){
        	hourHand = (((clockTime.hour % 24) * 60));
        } else {
        	hourHand = (((clockTime.hour % 24) * 60) + clockTime.min);
        }
        hourHand = hourHand / (24 * 60.0);
        hourHand = hourHand * Math.PI * 2;
        drawHand(dc, hourHand, 75, 8);
    }
    
    function drawMinuteHand(dc,height,width,clockTime){
        var minuteHand = (clockTime.min / 60.0) * Math.PI * 2;
        drawHand(dc, minuteHand, 90, 4);
    }
    
    function drawSecondsHand(dc,height,width,clockTime){
        // Draw the second if turned on
        if(Application.getApp().getProperty("@Properties.secondsHand")) {
	        if (isAwake) {            
	            var sh = (clockTime.sec / 60.0) * Math.PI * 2;
	            var st = sh - Math.PI;
	            drawHand(dc, sh, 75, 2);
	            drawHand(dc, st, 15, 2);//back tail of seconds hand
	        }
        }
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
    function drawHashMarks(dc,width,height) {
        var sX, sY;
        var eX, eY;
        var outerRad = width / 2;
        var innerRad = outerRad - 10;
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
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
    
    
    function drawNumbers(dc,width,height){
    	//clockwise starting at the top
    	dc.drawText(width / 2, 12, Gfx.FONT_XTINY , "00", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText((3*width/4)+13, 37, Gfx.FONT_XTINY, "03", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(width - 16, (height / 2) - 14, Gfx.FONT_XTINY, "06", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(3*width/4+17, 3*height/4-7, Gfx.FONT_XTINY, "09", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(width / 2, height - 37, Gfx.FONT_XTINY, "12", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 4-5, 3*height/4-7, Gfx.FONT_XTINY, "15", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(16, (height / 2) - 14, Gfx.FONT_XTINY, "18", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText((width/4)+5, 37, Gfx.FONT_XTINY, "21", Gfx.TEXT_JUSTIFY_RIGHT);
    }
    
    function drawBackground(dc){
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
    }

	function drawIndicators(dc,width,height){
		var battery = Sys.getSystemStats().battery.toLong();
		var tmphr = null;		
		//draw the battery outline, if applicable
		if(Application.getApp().getProperty("@Properties.batteryOutline")) {
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
		//get hr
		if(AM has :getHeartRateHistory){
			var tmphrHist =  AM.getHeartRateHistory(1, true);
			tmphr = tmphrHist.next().heartRate;
		} 
		//only draw heart rate if valid, otherwise don't draw icon as well
		if (tmphr != null && tmphr < 250) {
			hr = tmphr;
			var hrIconOffset = 0;
			if(hr < 100){
				hrIconOffset = width / 2 -40;
			} else {
				hrIconOffset = width / 2 -42;
			}
			dc.drawText((width/2) - 13, (height/2) + 20, Gfx.FONT_XTINY, hr, Gfx.TEXT_JUSTIFY_CENTER);
			dc.drawBitmap(hrIconOffset, (height/2) + 28, hrIcon);
		}
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
