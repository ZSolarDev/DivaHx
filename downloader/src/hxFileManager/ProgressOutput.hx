package hxFileManager;

import haxe.io.Output;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import sys.io.FileOutput;
import sys.io.File;

class ProgressOutput extends Output {
    var _buf:BytesBuffer;
    var _fileOut:FileOutput;
    var _streaming:Bool;
    var _onProgress:(Int, Int) -> Void;
    var _total:Int;

    public var received:Int = 0;
    public var closed:Bool = false;
    public var path:String = '';

    public function new(total:Int, onProgress:(Int, Int) -> Void, ?savePath:String) {
        _total = total;
        _onProgress = onProgress;
        _streaming = savePath != null && savePath != '';
        if (_streaming)
            path = savePath;

        if (_streaming)
            _fileOut = File.write(savePath, true);
        else
            _buf = new BytesBuffer();
    }

    override public function writeBytes(b:Bytes, pos:Int, len:Int):Int {
        if (_streaming)
            _fileOut.writeBytes(b, pos, len);
        else
            _buf.addBytes(b, pos, len);
    
        received += len;
        _onProgress(received, _total);
        return len;
    }

    public function getBytes():Bytes {
        return _streaming ? null : _buf.getBytes();
    }

    override public function close() {
        if (closed) return;
        closed = true;
        super.close();
        if (_streaming && _fileOut != null)
            _fileOut.close();
    }
}