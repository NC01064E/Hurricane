sub init()
    m.top.functionName = "fetchCalendar"
end sub

sub fetchCalendar()
    base = m.top.serviceUrl
    if base = invalid or base = "" then
        m.top.error = "SETUP"
        return
    end if
    if right(base, 1) = "/" then base = left(base, base.len() - 1)
    url = base + "/api/roku/events?pair=" + m.top.pairCode + "&days=31"
    xfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    xfer.SetMessagePort(port)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetUrl(url)
    xfer.AddHeader("Accept", "application/json")
    if m.top.deviceKey <> invalid and m.top.deviceKey <> "" then xfer.AddHeader("X-House-Key", m.top.deviceKey)
    if not xfer.AsyncGetToString() then
        m.top.error = "NETWORK"
        return
    end if
    response = wait(15000, port)
    if response = invalid or type(response) <> "roUrlEvent" then
        xfer.AsyncCancel()
        m.top.error = "TIMEOUT"
        return
    end if
    code = response.GetResponseCode()
    body = response.GetString()
    if code = 401 or code = 403 then
        m.top.error = "RECONNECT"
        return
    end if
    if code < 200 or code >= 300 then
        m.top.error = "HTTP " + code.toStr()
        return
    end if
    data = ParseJSON(body)
    if data = invalid then
        m.top.error = "INVALID RESPONSE"
        return
    end if
    m.top.payload = data
end sub
