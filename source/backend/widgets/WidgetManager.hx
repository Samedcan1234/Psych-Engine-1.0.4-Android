package backend.widgets;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

class WidgetManager
{
    public static var instance:WidgetManager;
    
    private var _parentGroup:FlxSpriteGroup;
    private var _activeWidgets:Map<String, WidgetBase> = new Map();
    private var _installedWidgets:Map<String, Bool> = new Map();
    
    // Widget varsayılan pozisyonları
    private var _defaultPositions:Map<String, {x:Float, y:Float}> = new Map();
    
    public function new(parentGroup:FlxSpriteGroup)
    {
        instance = this;
        _parentGroup = parentGroup;
        
        trace("=== WidgetManager created ===");
        
        setupDefaultPositions();
        loadInstalledWidgets();
    }
    
    private function setupDefaultPositions():Void
    {
        _defaultPositions.set("clock", {x: FlxG.width - 200, y: 20});
        _defaultPositions.set("visualizer", {x: FlxG.width - 200, y: 120});
    }
    
    public function loadInstalledWidgets():Void
    {
        trace("Loading installed widgets...");
        
        // Tüm widget ID'leri
        var widgetIds:Array<String> = ["clock", "visualizer"];
        
        for (id in widgetIds)
        {
            var installed = Reflect.field(FlxG.save.data, "widget_" + id + "_installed");
            var isInstalled:Bool = (installed == true);
            _installedWidgets.set(id, isInstalled);
            trace("  " + id + " = " + isInstalled);
        }
    }
    
    private function saveWidgetInstallState(widgetId:String, installed:Bool):Void
    {
        trace("Saving widget state: " + widgetId + " = " + installed);
        Reflect.setField(FlxG.save.data, "widget_" + widgetId + "_installed", installed);
        FlxG.save.flush();
    }
    
    public function initializeWidgets():Void
    {
        trace("=== Initializing widgets ===");
        for (widgetId in _installedWidgets.keys())
        {
            if (_installedWidgets.get(widgetId) == true)
            {
                trace("Creating widget: " + widgetId);
                createWidget(widgetId);
            }
        }
    }
    
    public function installWidget(widgetId:String):Bool
    {
        trace("=== installWidget: " + widgetId + " ===");
        
        if (_activeWidgets.exists(widgetId))
        {
            trace("Widget already active, skipping");
            return true;
        }
        
        _installedWidgets.set(widgetId, true);
        saveWidgetInstallState(widgetId, true);
        
        createWidget(widgetId);
        
        trace("Widget installed successfully");
        return true;
    }
    
    public function uninstallWidget(widgetId:String):Bool
    {
        trace("=== uninstallWidget: " + widgetId + " ===");
        
        _installedWidgets.set(widgetId, false);
        saveWidgetInstallState(widgetId, false);
        
        removeWidget(widgetId);
        
        trace("Widget uninstalled successfully");
        return true;
    }
    
	private function createWidget(widgetId:String):Void
	{
		trace("createWidget: " + widgetId);
		
		if (_activeWidgets.exists(widgetId))
		{
			trace("Widget already exists in _activeWidgets");
			return;
		}
		
		var defaultPos = _defaultPositions.get(widgetId);
		if (defaultPos == null)
		{
			defaultPos = {x: 100.0, y: 100.0};
		}
		
		var widget:WidgetBase = null;
		
		switch (widgetId)
		{
			case "clock":
				trace("Creating ClockWidget at " + defaultPos.x + ", " + defaultPos.y);
				widget = new ClockWidget(defaultPos.x, defaultPos.y);
			case "visualizer":
				trace("Creating MusicVisualizerWidget at " + defaultPos.x + ", " + defaultPos.y);
				// MusicVisualizerWidget kullan
				widget = new MusicVisualizerWidget(defaultPos.x, defaultPos.y);
			default:
				trace("Unknown widget: " + widgetId);
				return;
		}
		
		if (widget != null)
		{
			_activeWidgets.set(widgetId, widget);
			_parentGroup.add(widget);
			trace("Widget added to parent group");
		}
	}
    
    private function removeWidget(widgetId:String):Void
    {
        trace("removeWidget: " + widgetId);
        
        if (!_activeWidgets.exists(widgetId))
        {
            trace("Widget not in _activeWidgets");
            return;
        }
        
        var widget = _activeWidgets.get(widgetId);
        _parentGroup.remove(widget, true);
        widget.destroy();
        _activeWidgets.remove(widgetId);
        trace("Widget removed successfully");
    }
    
    public function isWidgetInstalled(widgetId:String):Bool
    {
        var installed = _installedWidgets.exists(widgetId) && _installedWidgets.get(widgetId) == true;
        return installed;
    }
    
    public function isWidgetActive(widgetId:String):Bool
    {
        return _activeWidgets.exists(widgetId);
    }
    
    public function getWidget(widgetId:String):WidgetBase
    {
        return _activeWidgets.get(widgetId);
    }
    
    public function toggleWidget(widgetId:String, install:Bool):Void
    {
        trace("=== toggleWidget: " + widgetId + " -> " + install + " ===");
        if (install)
            installWidget(widgetId);
        else
            uninstallWidget(widgetId);
    }
    
    public function getDefaultPosition(widgetId:String):{x:Float, y:Float}
    {
        return _defaultPositions.get(widgetId);
    }
    
    public function destroy():Void
    {
        trace("=== WidgetManager.destroy() ===");
        for (widget in _activeWidgets)
        {
            widget.destroy();
        }
        _activeWidgets.clear();
        _installedWidgets.clear();
        instance = null;
    }
}