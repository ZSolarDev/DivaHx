package hxFileManager;

import haxe.Int64;
import haxe.io.Output;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import sys.io.FileOutput;
import sys.io.File;

class ProgressOutput extends Output {
    var _buf:BytesBuffer;
    var _fileOut:FileOutput;
    var _streaming:Bool;
    var _onProgress:(Int64, Int64) -> Void;
    var _total:Int64;

    public var received:Int64 = 0;
    public var closed:Bool = false;
    public var path:String = '';

    public function new(total:Int64, onProgress:(Int64, Int64) -> Void, ?savePath:String) {
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
    
        received = Int64.add(received, Int64.ofInt(len));

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