// Do not edit this file! Generated by Ragel.
// Ragel.exe -G2 -J -o JsonReader.java JsonReader.rl
/*******************************************************************************
 * Copyright 2011 See AUTHORS file.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

package com.badlogic.gdx.utils;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;

import com.badlogic.gdx.files.FileHandle;

/** Lightweight JSON parser.<br>
 * <br>
 * The default behavior is to parse the JSON into a DOM made up of {@link OrderedMap}, {@link Array}, String, Float, and Boolean objects.
 * Extend this class and override methods to perform event driven parsing. When this is done, the parse methods will return null.
 * @author Nathan Sweet */
public class JsonReader {
	public Object parse (String json) {
		char[] data = json.toCharArray();
		return parse(data, 0, data.length);
	}

	public Object parse (Reader reader) {
		try {
			char[] data = new char[1024];
			int offset = 0;
			while (true) {
				int length = reader.read(data, offset, data.length - offset);
				if (length == -1) break;
				if (length == 0) {
					char[] newData = new char[data.length * 2];
					System.arraycopy(data, 0, newData, 0, data.length);
					data = newData;
				} else
					offset += length;
			}
			return parse(data, 0, offset);
		} catch (IOException ex) {
			throw new SerializationException(ex);
		} finally {
			try {
				reader.close();
			} catch (IOException ignored) {
			}
		}
	}

	public Object parse (InputStream input) {
		try {
			return parse(new InputStreamReader(input, "ISO-8859-1"));
		} catch (IOException ex) {
			throw new SerializationException(ex);
		}
	}

	public Object parse (FileHandle file) {
		try {
			return parse(file.read());
		} catch (Exception ex) {
			throw new SerializationException("Error parsing file: " + file, ex);
		}
	}

	public Object parse (char[] data, int offset, int length) {
		int cs, p = offset, pe = length, eof = pe, top = 0;
		int[] stack = new int[4];

		int s = 0;
		Array<String> names = new Array(8);
		boolean needsUnescape = false;
		boolean discardBuffer = false; // When unquotedString and true/false/null both match, this discards unquotedString.
		RuntimeException parseRuntimeEx = null;

		boolean debug = false;
		if (debug) System.out.println();

		try {
		%%{
			machine json;

			prepush {
				if (top == stack.length) {
					int[] newStack = new int[stack.length * 2];
					System.arraycopy(stack, 0, newStack, 0, stack.length);
					stack = newStack;
				}
			}

			action buffer {
				s = p;
				needsUnescape = false;
				discardBuffer = false;
			}
			action needsUnescape {
				needsUnescape = true;
			}
			action name {
				String name = new String(data, s, p - s);
				s = p;
				if (needsUnescape) name = unescape(name);
				if (debug) System.out.println("name: " + name);
				names.add(name);
			}
			action string {
				if (!discardBuffer) {
					String value = new String(data, s, p - s);
					s = p;
					if (needsUnescape) value = unescape(value);
					String name = names.size > 0 ? names.pop() : null;
					if (debug) System.out.println("string: " + name + "=" + value);
					string(name, value);
				}
			}
			action number {
				String value = new String(data, s, p - s);
				s = p;
				String name = names.size > 0 ? names.pop() : null;
				if (debug) System.out.println("number: " + name + "=" + Float.parseFloat(value));
				number(name, Float.parseFloat(value));
			}
			action trueValue {
				String name = names.size > 0 ? names.pop() : null;
				if (debug) System.out.println("boolean: " + name + "=true");
				bool(name, true);
				discardBuffer = true;
			}
			action falseValue {
				String name = names.size > 0 ? names.pop() : null;
				if (debug) System.out.println("boolean: " + name + "=false");
				bool(name, false);
				discardBuffer = true;
			}
			action null {
				String name = names.size > 0 ? names.pop() : null;
				if (debug) System.out.println("null: " + name);
				string(name, null);
				discardBuffer = true;
			}
			action startObject {
				String name = names.size > 0 ? names.pop() : null;
				if (debug) System.out.println("startObject: " + name);
				startObject(name);
				fcall object;
			}
			action endObject {
				if (debug) System.out.println("endObject");
				pop();
				fret;
			}
			action startArray {
				String name = names.size > 0 ? names.pop() : null;
				if (debug) System.out.println("startArray: " + name);
				startArray(name);
				fcall array;
			}
			action endArray {
				if (debug) System.out.println("endArray");
				pop();
				fret;
			}

			numberChars = '-'? [0-9]+ ('.' [0-9]+)? ([eE] [+\-]? [0-9]+)?;
			quotedChars = (^["\\] | ('\\' ["\\/bfnrtu] >needsUnescape))*;
			unquotedChars = [a-zA-Z_$] ^([:}\],] | space)*;
			name = ('"' quotedChars >buffer %name '"') | unquotedChars >buffer %name | numberChars >buffer %name;

			startObject = '{' @startObject;
			startArray = '[' @startArray;
			string = '"' quotedChars >buffer %string '"';
			unquotedString = unquotedChars >buffer %string;
			number = numberChars >buffer %number;
			nullValue = 'null' %null;
			booleanValue = 'true' %trueValue | 'false' %falseValue;
			value = startObject | startArray | number | string | nullValue | booleanValue | unquotedString $-1;

			nameValue = name space* ':' space* value;

			object := space* (nameValue space*)? (',' space* nameValue space*)** ','? space* '}' @endObject;

			array := space* (value space*)? (',' space* value space*)** ','? space* ']' @endArray;

			main := space* value space*;

			write init;
			write exec;
		}%%
		} catch (RuntimeException ex) {
			parseRuntimeEx = ex;
		}

		if (p < pe) {
			int lineNumber = 1;
			for (int i = 0; i < p; i++)
				if (data[i] == '\n') lineNumber++;
			throw new SerializationException("Error parsing JSON on line " + lineNumber + " near: " + new String(data, p, pe - p), parseRuntimeEx);
		} else if (elements.size != 0) {
			Object element = elements.peek();
			elements.clear();
			if (element instanceof OrderedMap)
				throw new SerializationException("Error parsing JSON, unmatched brace.");
			else
				throw new SerializationException("Error parsing JSON, unmatched bracket.");
		}
		Object root = this.root;
		this.root = null;
		return root;
	}

	%% write data;

	private final Array elements = new Array(8);
	private Object root, current;

	private void set (String name, Object value) {
		if (current instanceof OrderedMap)
			((OrderedMap)current).put(name, value);
		else if (current instanceof Array)
			((Array)current).add(value);
		else
			root = value;
	}

	protected void startObject (String name) {
		OrderedMap value = new OrderedMap();
		if (current != null) set(name, value);
		elements.add(value);
		current = value;
	}

	protected void startArray (String name) {
		Array value = new Array();
		if (current != null) set(name, value);
		elements.add(value);
		current = value;
	}

	protected void pop () {
		root = elements.pop();
		current = elements.size > 0 ? elements.peek() : null;
	}

	protected void string (String name, String value) {
		set(name, value);
	}

	protected void number (String name, float value) {
		set(name, value);
	}

	protected void bool (String name, boolean value) {
		set(name, value);
	}

	private String unescape (String value) {
		int length = value.length();
		StringBuilder buffer = new StringBuilder(length + 16);
		for (int i = 0; i < length;) {
			char c = value.charAt(i++);
			if (c != '\\') {
				buffer.append(c);
				continue;
			}
			if (i == length) break;
			c = value.charAt(i++);
			if (c == 'u') {
				buffer.append(Character.toChars(Integer.parseInt(value.substring(i, i + 4), 16)));
				i += 4;
				continue;
			}
			switch (c) {
			case '"':
			case '\\':
			case '/':
				break;
			case 'b':
				c = '\b';
				break;
			case 'f':
				c = '\f';
				break;
			case 'n':
				c = '\n';
				break;
			case 'r':
				c = '\r';
				break;
			case 't':
				c = '\t';
				break;
			default:
				throw new SerializationException("Illegal escaped character: \\" + c);
			}
			buffer.append(c);
		}
		return buffer.toString();
	}
}
