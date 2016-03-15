###
# Copyright (C) 2014-2016 Taiga Agile LLC <taiga@taiga.io>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# File: transfer-project.directive.coffee
###

module = angular.module('taigaProjects')

class TransferProject
    @.$inject = [
        "$routeParams",
        "tgProjectsService"
        "$location",
        "$tgAuth",
        "tgCurrentUserService",
        "$tgNavUrls",
        "$translate",
        "$tgConfirm"
    ]

    constructor: (@routeParams, @projectService, @location, @authService, @currentUserService, @navUrls, @translate, @confirmService) ->
        @.projectId = @.project.get("id")
        @.token = @routeParams.token
        @._refreshUserData()
        @.showAddComment = false

    _validateToken: () ->
        @projectService.transferValidateToken(@.projectId, @.token).error (data, status) =>
            @location.path(@navUrls.resolve("not-found"))

    _refreshUserData: () ->
        @authService.refresh().then () =>
            @._validateToken()
            @._setProjectData()
            @._checkOwnerData()

    _setProjectData: () ->
        @.canBeOwnedByUser = @currentUserService.canOwnProject(@.project)

    _checkOwnerData: () ->
        currentUser = @currentUserService.getUser()
        if(@.project.get('is_private'))
            @.ownerMessage = 'ADMIN.PROJECT_TRANSFER.OWNER_MESSAGE.PRIVATE'
            @.maxProjects = currentUser.get('max_private_projects')
            if @.maxProjects == null
                @.maxProjects = @translate.instant('ADMIN.PROJECT_TRANSFER.UNLIMITED_PROJECTS')
            @.currentProjects = currentUser.get('total_private_projects')
            maxMemberships = currentUser.get('max_memberships_private_projects')

        else
            @.ownerMessage = 'ADMIN.PROJECT_TRANSFER.OWNER_MESSAGE.PUBLIC'
            @.maxProjects = currentUser.get('max_public_projects')
            if @.maxProjects == null
                @.maxProjects = @translate.instant('ADMIN.PROJECT_TRANSFER.UNLIMITED_PROJECTS')
            @.currentProjects = currentUser.get('total_public_projects')
            maxMemberships = currentUser.get('max_memberships_public_projects')

        @.validNumberOfMemberships = maxMemberships == null || @.project.get('total_memberships') <= maxMemberships

    transferAccept: (token, reason) ->
        @projectService.transferAccept(@.project.get("id"), token, reason).success () =>
            newUrl = @navUrls.resolve("project-admin-project-profile-details", {
                project: @.project.get("slug")
            })
            @location.path(newUrl)
            @confirmService.notify("success", @translate.instant("ADMIN.PROJECT_TRANSFER.ACCEPTED_PROJECT_OWNERNSHIP"), '', 5000)

    transferReject: (token, reason) ->
        @projectService.transferReject(@.project.get("id"), token, reason).success () =>
            newUrl = @navUrls.resolve("project-admin-project-profile-details", {
                project: @project.get("slug")
            })
            @location.path(newUrl)
            @confirmService.notify("success", @translate.instant("ADMIN.PROJECT_TRANSFER.REJECTED_PROJECT_OWNERNSHIP"), '', 5000)

    addComment: () ->
        @.showAddComment = true

    hideComment: () ->
        @.showAddComment = false
        @.reason = ''



module.controller("TransferProjectController", TransferProject)
