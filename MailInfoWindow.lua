local Button = require("app.widgets.Button")

local Window = import("..Window")
local MailInfoWindow = class("MailInfoWindow", Window)

--senderDesLabel/subjectDesLabel的宽度定义，由CCS中测量得到
local TITLE_SENDER_DES_WIDTH  = 280
local TITLE_SUBJECT_DES_WIDTH = 460

--视图距父对象的间距定义
local BOARD_MARGIN_X = 10
local BOARD_MARGIN_Y = 10

--默认内容label的字体名称与尺寸
local CONTENT_FONT_NAME = "Arial"
local CONTENT_FONT_SIZE = 22

MailInfoWindow.ALL_ALLIANCE_MEM = "_c1076oYnYc1M"

--MailInfoWindow的Z值
MailInfoWindow.ZORDER = 16

--MailInfoWindow的状态，分为读页面/写页面
MailInfoWindow.STATUS_WRITE = 1
MailInfoWindow.STATUS_READ  = 2

--MailInfoWindow的按钮名称定义
MailInfoWindow.BUTTON_NAME = {
	"Write", "Friends", "Blacklist", "Delete"
}

--[[--------------------------------------------------------
--@des MailInfoWindow，邮件详情页面
--------------------------------------------------------]]--
function MailInfoWindow:ctor(category,
							 itemId,
							 canbeEdit,
							 status,
							 titleText,
							 sender,
							 subject,
							 text,
							 day,
							 time)
	MailInfoWindow.super.ctor(self, titleText)

	if sender == nil then
		sender = _T("客服团队")
	end
	self.sender = sender
	self.category = category
	self.itemId = itemId
	self.canbeEdit = canbeEdit
	self.status = status
	self.subject = subject or ""

	self:initBottom()
	self:initCenter(sender, subject, day, time, text)
end

--[[------------------------------------------
--@des 初始化邮件的底部视图，主要是邮件相关按钮
------------------------------------------]]--
function MailInfoWindow:initBottom()
	self.bottom = cc.CCSLoader.load(NS.RESCFG.ccs.mailInfoBottom, self)
	self:addChild(self.bottom, 1)
	NS.NODE_UTILS.setNodeAbsorbTouch(self.bottom)
	self.bottom:setAnchorPoint(cc.p(0.5, 0.5))
	self.bottom:setPosition(
		self:getContentSize().width / 2,
		self.bottom:getContentSize().height / 2 +
		BOARD_MARGIN_Y
	)

	if self.status == MailInfoWindow.STATUS_WRITE then
		--发送按钮
		if self.canbeEdit then
			self.sendButton:show()
		else
			self.deleteButton:show()
		end
	else
		self.writeButton:show()
		self.friendsButton:show()
		self.blacklistButton:show()
		self.deleteButton:show()
	end
end

--[[------------------------------------------
--@des 初始化中间视图
------------------------------------------]]--
function MailInfoWindow:initCenter(sender, subject, day, time, text)
	self:initCenterTitle(sender, subject, day, time)
	self:initCenterBody(text)
end

--[[------------------------------------------
--@des 初始化中间视图的title部分
------------------------------------------]]--
function MailInfoWindow:initCenterTitle(sender, subject, day, time)
	sender  = sender or ""
	subject = subject or ""
	day     = day or ""
	time    = time or ""

	--加载试图
	self.centerTitle = cc.CCSLoader.load(NS.RESCFG.ccs.mailInfoTitle, self)
	self:addChild(self.centerTitle, 1)
	NS.NODE_UTILS.setNodeAbsorbTouch(self.centerTitle)
	local contentWidth, contentHeight = self:getContentViewSize()
	self.centerTitle:setAnchorPoint(cc.p(0.5, 0.5))
	self.centerTitle:setPosition(
		contentWidth / 2,
		contentHeight -
		BOARD_MARGIN_Y -
		self.centerTitle:getContentSize().height / 2 + 10
	)

	--如果此视图用语收件箱查看
	--1.现实收件标题
	self.senderLabel:setString(_T("发件人："))
	self.subjectLabel:setString(_T("主    题："))

	self.senderBox:setString(sender)
	self.subjectBox:setString(subject)
	--2.内容不可编辑
	self.senderBox:setEnabled(false)
	self.subjectBox:setEnabled(false)
	--3.显示日期时间
	self.dayLabel:setString(day)
	self.timeLabel:setString(time)

	--如果是写信
	if self.status == MailInfoWindow.STATUS_WRITE then
		--设置显示收件人标题
		self.senderLabel:setString(_T("收件人："))

		if MailInfoWindow.ALL_ALLIANCE_MEM == sender then
			sender = "全体联盟成员"
			--发送给全体成员的内容不可被编辑
			self.senderBox:setTouchEnabled(false)
		end

		--收件人
		self.senderBox:setString(sender)
		--主题editBox
		self.subjectBox:setString(subject)
	end

	if self.canbeEdit then
		self.senderBox:setEnabled(true)
		self.subjectBox:setEnabled(true)
	else
		self.senderBox:setEnabled(false)
		self.subjectBox:setEnabled(false)
		self.senderBoard:hide()
		self.subjectBoard:hide()
	end
end

--[[---------------------------------------------------------
--@des 初始化中间视图的body部分，即背景图片和文字label
---------------------------------------------------------]]--
function MailInfoWindow:initCenterBody(content)
	local contentWidth, contentHeight = self:getContentViewSize()
	local width  = contentWidth - BOARD_MARGIN_X * 2
	local height = contentHeight -
				   self.bottom:getContentSize().height -
				   BOARD_MARGIN_Y * 2 -
				   self.centerTitle:getContentSize().height

	local x, y = getLayerPosAboutAnchor(self.centerTitle, display.LEFT_BOTTOM)
	
	cc.CCSLoader.load(NS.RESCFG.ccs.mailInfoCenter, self)
		:align(display.LEFT_TOP, 0, y)
		:addTo(self, 2)
	self.contentBox:setEnabled(false)
	self.contentBox:setString(content)
	if self.status == MailInfoWindow.STATUS_WRITE then
		self.contentBox:setEnabled(true)
	end
end

--[[-----------------------------------------
--@des 点击发送按钮
-----------------------------------------]]--
function MailInfoWindow:onSendBtnClick()
	local isAll
	if self.sender == MailInfoWindow.ALL_ALLIANCE_MEM then
		isAll = true
	end 
	local name = self.senderBox:getString()
	local title = self.subjectBox:getString()
	local cotent = self.contentBox:getString()
	app.controller:dispatchEvent({name = "MailNormalSendCommand", destNickname = name, title = title, content = cotent, isAll = isAll,
		callback = function (data)
			self:closeWindow()
		end})
end

--[[-----------------------------------------
--@des 点击写信按钮
-----------------------------------------]]--
function MailInfoWindow:onWriteBtnClick()
	print("MailInfoWindow:onWriteBtnClick")
	local text = self.senderBox:getString()

	local window = MailInfoWindow.new(
		nil,
		nil,
		true,
		MailInfoWindow.STATUS_WRITE,
		_T("写邮件"),
		text,
		"Re: "..self.subject

	)
	display.getRunningScene():addChild(window, MailInfoWindow.ZORDER)
end

--[[-----------------------------------------
--@des 点击加为好友按钮
-----------------------------------------]]--
function MailInfoWindow:onFriendsBtnClick()
	local text = self.senderBox:getString()
	app.controller:dispatchEvent({name = "FriendAddCommand", nickName = text})
end

--[[-----------------------------------------
--@des 点击加入黑名单按钮
-----------------------------------------]]--
function MailInfoWindow:onBlacklistBtnClick()
	local text = self.senderBox:getString()
	app.controller:dispatchEvent({name = "BlackAddCommand", nickName = text})
end

--[[-----------------------------------------
--@des 点击清空按钮
-----------------------------------------]]--
function MailInfoWindow:onDeleteBtnClick()
	if self.itemId and self.category then
		app.controller:dispatchEvent({name = "MailDeleteCommand", ids = {self.itemId}, typeId = self.category, callback = function()
			self:closeWindow()
		end})
	end
end

return MailInfoWindow