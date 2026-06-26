package hxFileManager;

import haxe.Exception;
import haxe.io.BytesOutput;
import haxe.std.sys.DHttp;
import haxe.Json;
import haxe.io.Bytes;
import haxe.Timer;
import sys.io.File;

class HttpManager {

	public static var hasInternet:Bool = checkInternet();
	public static var defaultUserAgent:String = "hxFileManager";
	public static var defaultTimeout:Int = 10;
    public static var output:ProgressOutput;

	/** Request text from a URL. @param url Target URL. @param headers Optional headers. @param maxRedirects Max redirects to follow (default 5). @param onProgress Optional progress callback (downloaded, total). */
	public static function requestText(url:String, ?headers:Map<String, String>, maxRedirects:Int = 5, ?onProgress:(Int, Int)->Void):String
		return requestBytes(url, headers, maxRedirects, onProgress).toString();

	/** Request raw bytes from a URL. @param url Target URL. @param headers Optional headers. @param maxRedirects Max redirects to follow (default 5). @param onProgress Optional progress callback (downloaded, total). */
	public static function requestBytes(url:String, ?headers:Map<String, String>, maxRedirects:Int = 5, ?onProgress:(Int, Int)->Void, ?savePath:String = '', ?chunkSize:Int = -1):Bytes {
        if (maxRedirects < 0) throw new HttpError(new Exception("Too many redirects"), url);

        var error:HttpError = null;
        var statusCode:Int = -1;

        var contentLength = -1;
        if (onProgress != null || chunkSize > 0) {
            var headH = buildRequest(url, headers);
            headH.onStatus = (code:Int) -> statusCode = code;
            headH.onError = (_) -> {};
            try headH.customRequest(false, new BytesOutput(), null, "HEAD")
            catch (_:Dynamic) {}
            var lenStr = headH.responseHeaders?.get("Content-Length") ?? headH.responseHeaders?.get("content-length");
            if (lenStr != null) contentLength = Std.parseInt(lenStr);
        }

        // chunked mode
        if (chunkSize != null && chunkSize > 0 && savePath != null && savePath != '' && contentLength > 0) {
            var startByte = 0;
            if (sys.FileSystem.exists(savePath))
                startByte = sys.FileSystem.stat(savePath).size;

            if (startByte >= contentLength)
                return null; // already fully downloaded

            var out = startByte > 0 ? File.append(savePath, true) : File.write(savePath, true);
            var current = startByte;
            var totalReceivedSoFar = startByte;

            while (current < contentLength) {
                var rangeEnd = (current + chunkSize - 1 < contentLength) ? (current + chunkSize - 1) : (contentLength - 1);
                var rangeHeaders = headers == null ? new Map<String, String>() : copyHeaders(headers);
                rangeHeaders.set("Range", 'bytes=$current-$rangeEnd');

                var h = buildRequest(url, rangeHeaders);
                h.onError = (err:Exception) -> error = new HttpError(err, url);
                h.onStatus = (code:Int) -> statusCode = code;

                var chunkStart = current; // capture for the closure below
                var chunkOutput = new ProgressOutput(rangeEnd - chunkStart + 1, (chunkCur, chunkTotal) -> {
                    if (onProgress != null) onProgress(chunkStart + chunkCur, contentLength);
                });
            
                try h.customRequest(false, chunkOutput)
                catch (e:Dynamic) { chunkOutput.close(); out.close(); throw new HttpError(e, url); }
            
                if (error != null) { chunkOutput.close(); out.close(); throw error; }

                var chunkBytes = chunkOutput.getBytes();
                chunkOutput.close();

                if (chunkBytes.length == 0) { out.close(); throw new HttpError(new Exception("Empty chunk response"), url, statusCode); }

                out.writeBytes(chunkBytes, 0, chunkBytes.length);
                current += chunkBytes.length;
            }

            out.close();
            return null;
        }

        // non-chunked path
        var h = buildRequest(url, headers);
        h.onError = (err:Exception) -> error = new HttpError(err, url);
        h.onStatus = (code:Int) -> statusCode = code;

        output = new ProgressOutput(contentLength, onProgress, savePath);

        try h.customRequest(false, output)
        catch (e:Dynamic) { output.close(); throw new HttpError(e, url); }

        if (onProgress != null)
            onProgress(output.received, contentLength);

        if (error != null) { output.close(); throw error; }

        if (isRedirect(statusCode)) {
            output.close();
            var location = h.responseHeaders != null ? (h.responseHeaders.get("Location") ?? h.responseHeaders.get("location")) : null;
            if (location == null) throw new HttpError(new Exception("Redirect missing Location header"), url, statusCode, true);
            return requestBytes(location, headers, maxRedirects - 1, onProgress, savePath, chunkSize);
        }

        output.close();

        if (savePath != null && savePath != '')
            return null;

        var result = output.getBytes();
        if (result == null || result.length == 0) throw new HttpError(new Exception("Empty response"), url, statusCode);
        return result;
    }

    static function copyHeaders(m:Map<String, String>):Map<String, String> {
        var copy = new Map<String, String>();
        for (k => v in m) copy.set(k, v);
        return copy;
    }

	/** POST JSON data to a URL. @param url Target URL. @param data Object to serialise as JSON body. @param headers Optional extra headers. @param onSuccess Optional callback with response text. @param onError Optional callback with error message. */
	public static function postJson(url:String, data:Dynamic, ?headers:Map<String, String>, ?onSuccess:String->Void, ?onError:Exception->Void):Void {
		var h = buildRequest(url, headers);
		h.setHeader("Content-Type", "application/json");
		h.setPostData(Json.stringify(data));
		h.onData = (d:String) -> if (onSuccess != null) onSuccess(d);
		h.onError = (error:Exception) -> if (onError != null) onError(error);
		try h.request(true)
		catch (e:Dynamic) if (onError != null) onError(e);
	}

	/** POST form-encoded key-value pairs to a URL. @param url Target URL. @param fields Map of field name to value. @param headers Optional extra headers. @param onSuccess Optional callback with response text. @param onError Optional callback with error message. */
	public static function postForm(url:String, fields:Map<String, String>, ?headers:Map<String, String>, ?onSuccess:String->Void, ?onError:Exception->Void):Void {
		var h = buildRequest(url, headers);
		h.setHeader("Content-Type", "application/x-www-form-urlencoded");
		var parts:Array<String> = [];
		for (k => v in fields) parts.push(StringTools.urlEncode(k) + "=" + StringTools.urlEncode(v));
		h.setPostData(parts.join("&"));
		h.onData = (d:String) -> if (onSuccess != null) onSuccess(d);
		h.onError = (error:Exception) -> if (onError != null) onError(error);
		try h.request(true)
		catch (e:Dynamic) if (onError != null) onError(e);
	}

	/** Send a DELETE request. @param url Target URL. @param headers Optional headers. @param onSuccess Optional callback with response text. @param onError Optional callback with error message. */
	public static function delete(url:String, ?headers:Map<String, String>, ?onSuccess:String->Void, ?onError:Exception->Void):Void {
		var h = buildRequest(url, headers);
		h.setHeader("X-HTTP-Method-Override", "DELETE");
		h.onData = (d:String) -> if (onSuccess != null) onSuccess(d);
		h.onError = (error:Exception) -> if (onError != null) onError(error);
		try h.request(false)
		catch (e:Dynamic) if (onError != null) onError(e);
	}

	/** Send a PUT request with a JSON body. @param url Target URL. @param data Object to serialise as JSON body. @param headers Optional extra headers. @param onSuccess Optional callback with response text. @param onError Optional callback with error message. */
	public static function putJson(url:String, data:Dynamic, ?headers:Map<String, String>, ?onSuccess:String->Void, ?onError:Exception->Void):Void {
		var h = buildRequest(url, headers);
		h.setHeader("Content-Type", "application/json");
		h.setHeader("X-HTTP-Method-Override", "PUT");
		h.setPostData(Json.stringify(data));
		h.onData = (d:String) -> if (onSuccess != null) onSuccess(d);
		h.onError = (error:Exception) -> if (onError != null) onError(error);
		try h.request(true)
		catch (e:Dynamic) if (onError != null) onError(e);
	}

	/** Send a PATCH request with a JSON body. @param url Target URL. @param data Object to serialise as JSON body. @param headers Optional extra headers. @param onSuccess Optional callback with response text. @param onError Optional callback with error message. */
	public static function patchJson(url:String, data:Dynamic, ?headers:Map<String, String>, ?onSuccess:String->Void, ?onError:Exception->Void):Void {
		var h = buildRequest(url, headers);
		h.setHeader("Content-Type", "application/json");
		h.setHeader("X-HTTP-Method-Override", "PATCH");
		h.setPostData(Json.stringify(data));
		h.onData = (d:String) -> if (onSuccess != null) onSuccess(d);
		h.onError = (error:Exception) -> if (onError != null) onError(error);
		try h.request(true)
		catch (e:Dynamic) if (onError != null) onError(e);
	}

	/** Fetch a URL and parse the response as JSON. @param url Target URL. @param headers Optional headers. @param onSuccess Callback with parsed JSON. @param onError Optional error callback. */
	public static function getJson(url:String, ?headers:Map<String, String>, onSuccess:Dynamic->Void, ?onError:Exception->Void):Void {
		var h = buildRequest(url, headers);
		h.setHeader("Accept", "application/json");
		h.onData = (d:String) -> {
			try onSuccess(Json.parse(d))
			catch (e:Dynamic) if (onError != null) onError(e);
		};
		h.onError = (error:Exception) -> if (onError != null) onError(error);
		try h.request(false)
		catch (e:Dynamic) if (onError != null) onError(e);
	}

	/** Download a URL to a local file path. @param url Remote URL. @param savePath Local destination path. @param headers Optional headers. @param onProgress Optional progress callback (downloaded, total). @param onDone Optional completion callback. @param onError Optional error callback. */
	public static function downloadTo(url:String, savePath:String, ?headers:Map<String, String>, ?onProgress:(Int, Int)->Void, ?onDone:Void->Void, ?onError:Exception->Void, ?chunkSize:Int = -1):Void {
        try {
            requestBytes(url, headers, 5, onProgress, savePath, chunkSize);
            if (onDone != null) onDone();
        } catch (e) {
            if (onError != null) onError(e);
        }
    }

	/** Check if a URL returns any bytes without throwing. @param url Target URL. @param headers Optional headers. */
	public static function hasBytes(url:String, ?headers:Map<String, String>):Bool {
		try return requestBytes(url, headers) != null
		catch (_) return false;
	}

	/** Return the HTTP status code for a URL without downloading the body. @param url Target URL. @param headers Optional headers. */
	public static function getStatusCode(url:String, ?headers:Map<String, String>):Int {
		var code = -1;
		var h = buildRequest(url, headers);
		h.onStatus = (c:Int) -> code = c;
		h.onBytes = (_) -> {};
		h.onError = (_) -> {};
		try h.request(false) catch (_) {}
		return code;
	}

	/** Return all response headers for a URL. @param url Target URL. @param headers Optional request headers. */
	public static function getResponseHeaders(url:String, ?headers:Map<String, String>):Map<String, String> {
		var h = buildRequest(url, headers);
		h.onBytes = (_) -> {};
		h.onError = (_) -> {};
		try h.request(false) catch (_) {}
		return h.responseHeaders ?? new Map();
	}

	/** Retry a request up to maxAttempts times with an optional delay between attempts. @param url Target URL. @param maxAttempts Max number of attempts (default 3). @param delayMs Milliseconds to wait between attempts (default 500). @param headers Optional headers. */
	public static function requestWithRetry(url:String, maxAttempts:Int = 3, delayMs:Int = 500, ?headers:Map<String, String>):Bytes {
		var lastErr:Dynamic = null;
		for (i in 0...maxAttempts) {
			try return requestBytes(url, headers)
			catch (e:Dynamic) {
				lastErr = e;
				if (i < maxAttempts - 1) Sys.sleep(delayMs / 1000.0);
			}
		}
		throw lastErr;
	}

	/** Check internet connectivity by hitting a lightweight URL. Updates hasInternet. */
	public static function checkInternet():Bool {
		try {
			hasInternet = requestText("https://example.com") != null;
		} catch (_) {
			hasInternet = false;
		}
		return hasInternet;
	}

	/** Check internet connectivity asynchronously via a timer-based approach. @param onResult Callback with true if internet is reachable. */
	public static function checkInternetAsync(onResult:Bool->Void):Void {
		Timer.delay(() -> onResult(checkInternet()), 0);
	}

	static function buildRequest(url:String, ?headers:Map<String, String>):DHttp {
		var h = new DHttp(url);
		h.setHeader("User-Agent", defaultUserAgent);
		if (headers != null) for (k => v in headers) h.setHeader(k, v);
		return h;
	}

	static function isRedirect(status:Int):Bool {
        return status == 301 || status == 302 || status == 303 || status == 307 || status == 308;
    }
}

class HttpError {
	public var error:Exception;
	public var url:String;
	public var status:Int;
	public var redirected:Bool;

	public function new(error:Exception, url:String, status:Int = -1, redirected:Bool = false) {
		this.error = error;
		this.url = url;
		this.status = status;
		this.redirected = redirected;
	}

	public function toString():String {
		var parts = ["[HttpManager | ERROR]"];
		if (status != -1) parts.push('Status: $status');
		if (redirected) parts.push("(Redirected)");
		parts.push('URL: $url');
		parts.push('Message: ${error.message}');
        parts.push('\nStack:${error.stack}\n');
		return parts.join(" | ");
	}
}
