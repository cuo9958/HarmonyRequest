import http from '@ohos.net.http';
import request from '@ohos.request';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

interface IOpts {
  baseUrl?: string;
}

interface IResponseData<T> {
  code: number;
  msg: string;
  data: null | undefined | T;
}

type IArgs = string | number | boolean

interface IFormData {
  name: string;
  contentType: 'text/plain' | 'image/png' | 'image/jpeg' | 'audio/mpeg' | 'video/mp4';
  data?: string;
  remoteFileName?: string;
  filePath?: string
}

export default class HttpRequest {
  baseUrl = ''

  constructor(opts?: IOpts) {
    if (opts?.baseUrl) {
      this.baseUrl = opts.baseUrl
    }
  }

  // 简易无参数版本
  get<T>(url: string) {
    return this._request<T>(http.RequestMethod.GET, url)
  }

  getMap<T>(url: string, params: Map<string, string | number>) {
    if (!url.includes("?")) {
      url += "?"
    }
    params.forEach((v, k) => url += `&${k}=${encodeURIComponent(v)}`)
    return this._request<T>(http.RequestMethod.GET, url)
  }

  getArray<T>(url: string, params: Array<Array<string | number>>) {
    if (!url.includes("?")) {
      url += "?"
    }
    params.forEach((v) => url += `&${v[0]}=${encodeURIComponent(v[1])}`)
    return this._request<T>(http.RequestMethod.GET, url)
  }

  getArgs<T>(url: string, k1?: string, v1?: IArgs, k2?: string, v2?: IArgs, k3?: string, v3?: IArgs) {
    if (!url.includes("?")) {
      url += "?"
    }
    if (k1 && v1) {
      url += `&${k1}=${encodeURIComponent(v1)}`
    }
    if (k2 && v2) {
      url += `&${k2}=${encodeURIComponent(v2)}`
    }
    if (k3 && v3) {
      url += `&${k3}=${encodeURIComponent(v3)}`
    }
    return this._request<T>(http.RequestMethod.GET, url)
  }

  getString<T>(url: string, ...params: string[]) {
    if (!url.includes("?")) {
      url += "?"
    }
    url += params.join("&");
    return this._request<T>(http.RequestMethod.GET, url)
  }

  post<T>(url: string, data: string) {
    return this._request<T>(http.RequestMethod.POST, url, data)
  }

  postObject<T>(url: string, data: Object) {
    return this._request<T>(http.RequestMethod.POST, url, JSON.stringify(data))
  }

  postFormData<T>(url: string, data: IFormData[]) {
    return this._requestFormData<T>(url, data)
  }

  token = ""

  setToken(token: string) {
    this.token = token
    this.headers.set("token", token)
  }

  headers = new Map<string, string>([["Content-Type", "application/json"]])

  setHeader(name: string, value: string) {
    this.headers.set(name, value)
  }

  delHeader(name: string) {
    this.headers.delete(name)
  }

  /**
   * 基础请求库
   * @param method
   * @param url
   * @param data
   */
  private async _request<T>(method: http.RequestMethod, url: string, data?: string): Promise<T | null | undefined> {

    let httpRequest = http.createHttp();

    let header = this.headers
    const res = await httpRequest.request(this.baseUrl + url, {
      method,
      header: header,
      extraData: data,
      expectDataType: http.HttpDataType.OBJECT,
      connectTimeout: 10000,
      readTimeout: 10000,
    })
    httpRequest.destroy();
    if (res.responseCode !== 200) throw new Error("网络链接失败")
    const res_data = res.result as IResponseData<T>
    // 判定是否需要登录
    if (res_data.code === 429) {
      router.pushUrl({
        url: "pages/login"
      })
      return null
    }
    if (res_data.code !== 1) throw new Error(res_data.msg)
    return res_data.data
  }

  private async _requestFormData<T>(url: string, data: IFormData[]): Promise<T | null | undefined> {

    let httpRequest = http.createHttp();
    const res = await httpRequest.request(this.baseUrl + url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json'
      },
      multiFormDataList: data,
      expectDataType: http.HttpDataType.OBJECT,
      connectTimeout: 10000,
      readTimeout: 10000,
    })
    httpRequest.destroy();
    if (res.responseCode !== 200) throw new Error("网络链接失败")
    const res_data = res.result as IResponseData<T>
    if (res_data.code !== 1) throw new Error(res_data.msg)
    return res_data.data
  }

  async uploadFile(url: string, file: request.File) {
    let context = getContext(this) as common.UIAbilityContext;
    request.uploadFile(context, {
      url: this.baseUrl + url,
      method: http.RequestMethod.POST,
      files: [file],
      header: new Map(),
      data: []
    }).then(task => {
      task.on("complete", () => {

      })
    }).catch((err: Error) => console.log(err.message))
  }
}

interface ITest {
  msg: string
}

const axios = new HttpRequest();

async function testGet(a: string, b: number) {
  try {
    const data = await axios.get<ITest>(`http://127.0.0.1:3000?a=${a}&b=${b}`)
  } catch (e) {
    console.log(e.message)
  }
}

async function testGetMap(a: string, b: number) {
  try {
    const params = new Map<string, string | number>()
    params.set("a", a)
    params.set("b", b)
    const data = await axios.getMap<ITest>("http://127.0.0.1:3000", params)
  } catch (e) {
    console.log(e.message)
  }
}

async function testGetArray(a: string, b: number) {
  try {
    const params = [["a", a], ["b", b]]

    const data = await axios.getArray<ITest>("http://127.0.0.1:3000", params)
  } catch (e) {
    console.log(e.message)
  }
}

async function testGetArgs(a: string, b: number) {
  try {

    const data = await axios.getArgs<ITest>("http://127.0.0.1:3000", "a", a, "b", b)
  } catch (e) {
    console.log(e.message)
  }
}

async function testGetString(a: string, b: number) {
  try {

    const data = await axios.getString<ITest>("http://127.0.0.1:3000", "a=" + a, "b=" + b)
  } catch (e) {
    console.log(e.message)
  }
}

async function testPost(a: string, b: number) {
  try {

    const data = await axios.post<ITest>("http://127.0.0.1:3000", JSON.stringify({ a, b }))
  } catch (e) {
    console.log(e.message)
  }
}

interface IParams {
  a: string,
  b: number
}

async function testPostObject(a: string, b: number) {
  try {
    const params: IParams = { a, b }
    const data = await axios.postObject<ITest>("http://127.0.0.1:3000", params)
  } catch (e) {
    console.log(e.message)
  }
}

async function testPostFormData(a: string) {
  try {

    const data = await axios.postFormData<ITest>("http://127.0.0.1:3000", [{
      name: "a",
      contentType: "text/plain",
      data: a
    }, {
      name: "file",
      contentType: "text/plain",
      filePath: `/data/app/el2/100/base/com.example.myapplication/haps/entry/files/fileName.txt`,
      remoteFileName: 'fileName.txt'
    }])
  } catch (e) {
    console.log(e.message)
  }
}
